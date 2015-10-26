package notification

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	socialapimodels "socialapi/models"
	"socialapi/request"
	"socialapi/workers/notification/models"
	"time"

	multierror "github.com/hashicorp/go-multierror"
	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

const (
	NOTIFICATION_TYPE_SUBSCRIBE   = "subscribe"
	NOTIFICATION_TYPE_UNSUBSCRIBE = "unsubscribe"
)

type Controller struct {
	log     logging.Logger
	rmqConn *amqp.Connection
}

func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred: %s", err)
	delivery.Ack(false)

	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) *Controller {
	return &Controller{
		log:     log,
		rmqConn: rmq.Conn(),
	}
}

// CreateReplyNotification notifies main thread owner.
func (c *Controller) CreateReplyNotification(mr *socialapimodels.MessageReply) error {
	cm, err := socialapimodels.Cache.Message.ById(mr.MessageId)
	if err != nil {
		return err
	}

	if cm.TypeConstant != socialapimodels.ChannelMessage_TYPE_POST {
		return nil
	}

	// fetch replier
	reply, err := socialapimodels.Cache.Message.ById(mr.ReplyId)
	if err != nil {
		return err
	}

	groupChannel, err := reply.FetchParentChannel()
	if err != nil {
		return err
	}

	rn := models.NewReplyNotification()
	rn.TargetId = mr.MessageId
	rn.NotifierId = reply.AccountId
	rn.MessageId = reply.Id

	subscribedAt := time.Now().UTC()

	nc, err := models.CreateNotificationContent(rn)
	if err != nil {
		return err
	}

	// if it is not notifier's own message then add replier to subscribers
	// for further reply notifications
	if cm.AccountId != rn.NotifierId {
		c.subscribe(nc.Id, cm.AccountId, subscribedAt, groupChannel)
	}

	notifiedUsers, err := rn.GetNotifiedUsers(nc.Id)
	if err != nil {
		return err
	}

	mentionedUsers, err := c.CreateMentionNotification(reply, cm.Id)
	if err != nil {
		return err
	}

	// if a user is already subscribed to a post, and also mentioned in a reply
	// just send mention notification -no need for reply notification.
	notifiedUsers = filterRepliers(notifiedUsers, mentionedUsers)

	notifierSubscribed := false
	for _, recipient := range notifiedUsers {
		if recipient == rn.NotifierId {
			notifierSubscribed = true
		}
		c.notify(nc.Id, recipient, groupChannel, true)
	}

	if !notifierSubscribed {
		c.subscribe(nc.Id, rn.NotifierId, subscribedAt, groupChannel)
	}

	return nil
}

// func (n *Controller) UnsubscribeMessage(data *socialapimodels.ChannelMessageList) error {
// 	return subscription(data, NOTIFICATION_TYPE_UNSUBSCRIBE)
// }

//func subscription(cml *socialapimodels.ChannelMessageList, typeConstant string) error {
//    c := socialapimodels.NewChannel()
//    if err := c.ById(cml.ChannelId); err != nil {
//        return err
//    }

//    if c.TypeConstant != socialapimodels.Channel_TYPE_PINNED_ACTIVITY {
//        return nil
//    }

//     user pinned (followed) a message
//    nc := models.NewNotificationContent()
//    nc.TargetId = cml.MessageId

//    n := models.NewNotification()
//    n.AccountId = c.CreatorId

//    switch typeConstant {
//    case NOTIFICATION_TYPE_SUBSCRIBE:
//        return n.Subscribe(nc)
//    case NOTIFICATION_TYPE_UNSUBSCRIBE:
//        return n.Unsubscribe(nc)
//    }

//    return nil
//}

func (c *Controller) HandleMessage(cm *socialapimodels.ChannelMessage) error {
	if cm.TypeConstant != socialapimodels.ChannelMessage_TYPE_POST {
		return nil
	}

	_, err := c.CreateMentionNotification(cm, cm.Id)
	return err
}

func (c *Controller) DeleteNotification(cm *socialapimodels.ChannelMessage) error {
	nc := models.NewNotificationContent()
	contentIds, err := nc.FetchIdsByTargetId(cm.Id)
	if err != nil {
		return err
	}

	if len(contentIds) == 0 {
		return nil
	}

	return models.NewNotification().HideByContentIds(contentIds)
}

// CreateMentionNotification creates mention notifications for the related channel messages
func (c *Controller) CreateMentionNotification(cm *socialapimodels.ChannelMessage, targetId int64) ([]int64, error) {
	usernames := cm.GetMentionedUsernames()

	// message does not contain any mentioned users
	if len(usernames) == 0 {
		return nil, nil
	}

	mentionedUsers, err := socialapimodels.FetchAccountsByNicks(usernames)
	if err != nil {
		return nil, err
	}

	return c.handleUsernameMentions(cm, targetId, mentionedUsers)
}

// normalizeUsernames converts aliases to their respective usernames
func normalizeUsernames(cm *socialapimodels.ChannelMessage, usernames []string) ([]string, error) {
	normalizeUsernames := make([]string, 0)

	for alias := range globalAliases {
		for _, username := range usernames {
			if alias == username {
				channelUsers, err := fetchAllMembersOfAGroup(cm)
				if err != nil {
					return nil, err
				}
				normalizeUsernames = append(normalizeUsernames, channelUsers...)
			} else {
				normalizeUsernames = append(normalizeUsernames, username)
			}
		}
	}

	for alias := range roleAliases {
		for _, username := range usernames {
			if alias == username {
				channelUsers, err := fetchAllMembersOfChannel(cm)
				if err != nil {
					return nil, err
				}
				normalizeUsernames = append(normalizeUsernames, channelUsers...)
			} else {
				normalizeUsernames = append(normalizeUsernames, username)
			}
		}
	}

	return socialapimodels.UnifyStringSlice(normalizeUsernames), nil
}

// fetchAllMembersOfAGroup gets the group name from the channel message and
// returns all the user's nicknames of that group
func fetchAllMembersOfAGroup(cm *socialapimodels.ChannelMessage) ([]string, error) {
	groupChannel, err := cm.FetchParentChannel() // it has internal caching
	if err != nil {
		return nil, err
	}

	return fetchChannelParticipants(groupChannel)
}

// fetchAllMembersOfChannel gets the channel id from ChannelMessage and fetches
// all the participants of that channel, returns only the usernames
func fetchAllMembersOfChannel(cm *socialapimodels.ChannelMessage) ([]string, error) {
	c, err := socialapimodels.Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return nil, err
	}

	return fetchChannelParticipants(c)
}

// fetchAllAdminsOfChannel fetches all the admins of a group and return their
// usernames
func fetchAllAdminsOfChannel(cm *socialapimodels.ChannelMessage) ([]string, error) {
	c, err := socialapimodels.Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return nil, err
	}

	admins, err := modelhelper.FetchAdminAccounts(c.GroupName)
	if err != nil {
		return nil, err
	}

	adminNicknames := make([]string, len(admins))
	for i, admin := range admins {
		adminNicknames[i] = admin.Profile.Nickname
	}

	return adminNicknames, nil
}

// fetchChannelParticipants fetches all the participants of the given channel,
// returns only the usernames of the account
func fetchChannelParticipants(c *socialapimodels.Channel) ([]string, error) {
	q := request.NewQuery()
	ids, err := c.FetchParticipantIds(q)
	if err != nil {
		return nil, err
	}

	var errs *multierror.Error

	usernames := make([]string, 0)
	for _, id := range ids {
		acc, err := socialapimodels.Cache.Account.ById(id)
		if err != nil {
			errs = multierror.Append(errs, err)
		}

		usernames = append(usernames, acc.Nick)
	}

	if errs.ErrorOrNil() != nil {
		return nil, errs
	}

	return usernames, nil
}

var globalAliases = map[string][]string{
	"all":     []string{"team", "all", "group"},
	"channel": []string{"channel"},
}

var roleAliases = map[string][]string{
	"admins": []string{"admins"},
}

type aliasNormalizerFunc func(*socialapimodels.ChannelMessage) ([]string, error)

var aliasNormalier = map[string]aliasNormalizerFunc{
	"all":     fetchAllMembersOfAGroup,
	"channel": fetchAllMembersOfChannel,
	"admins":  fetchAllAdminsOfChannel,
}

// clean up removes duplicate mentions from usernames. eg: team and all
// essentially same mentions
func cleanup(usernames []string) []string {
	cleanUsernames := make(map[string]struct{})

	for _, username := range usernames {
		// check if the username is in global mention list first
		for mention, aliases := range globalAliases {
			if socialapimodels.IsIn(username, aliases...) {
				// if we have "all" mention (or any other all `alias`), no need
				// for further process
				if mention == "all" {
					return []string{"all"}
				}

				// if the username is one the keywords, just use the general keyword
				cleanUsernames[mention] = struct{}{}
			} else {
				// if username is not one of the keywords, use it directly
				cleanUsernames[username] = struct{}{}
			}
		}
	}

	// then check if the username is in
	for cleaned := range cleanUsernames {
		for mention, aliases := range roleAliases {
			if socialapimodels.IsIn(cleaned, aliases...) {
				delete(cleanUsernames, cleaned)      // delete the alias from clean
				cleanUsernames[mention] = struct{}{} // set mention to clean
			} else {
				cleanUsernames[cleaned] = struct{}{}
			}
		}
	}

	// convert it to string slice
	res := make([]string, 0)
	for username := range cleanUsernames {
		res = append(res, username)
	}

	return res
}

func (c *Controller) handleUsernameMentions(cm *socialapimodels.ChannelMessage, targetId int64, mentionedUsers []socialapimodels.Account) ([]int64, error) {
	groupChannel, err := cm.FetchParentChannel() // it has internal caching
	if err != nil {
		return nil, err
	}

	mentionedUserIds := make([]int64, 0)

	for _, mentionedUser := range mentionedUsers {
		// if user mentions herself ignore it
		if mentionedUser.Id == cm.AccountId {
			continue
		}

		mn := models.NewMentionNotification()
		mn.TargetId = targetId
		mn.MessageId = cm.Id
		mn.NotifierId = cm.AccountId
		nc, err := models.CreateNotificationContent(mn)
		if err != nil {
			return nil, err
		}

		c.instantNotify(nc.Id, mentionedUser.Id, groupChannel, true)

		mentionedUserIds = append(mentionedUserIds, mentionedUser.Id)
	}

	return mentionedUserIds, nil
}

func (c *Controller) notify(contentId, notifierId int64, contextChannel *socialapimodels.Channel, checkForParticipation bool) {
	if checkForParticipation {
		isParticipant, err := isParticipant(notifierId, contextChannel)
		if err != nil {
			c.log.Error("Could not check participation info for user %d: %s", notifierId, err)
			return
		}

		// when mentioned user does not exist within the group, do not send notification
		if !isParticipant {
			return
		}
	}

	notification := newNotification(contentId, notifierId, time.Now().UTC())
	notification.ContextChannelId = contextChannel.Id
	if err := notification.Upsert(); err != nil {
		c.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func (c *Controller) instantNotify(contentId, notifierId int64, contextChannel *socialapimodels.Channel, checkForParticipation bool) {
	// if we need to check for participation, do here
	if checkForParticipation {
		isParticipant, err := isParticipant(notifierId, contextChannel)
		if err != nil {
			c.log.Error("Could not check participation info for user %d: %s", notifierId, err)
			return
		}

		// when mentioned user does not exist within the group, do not send notification
		if !isParticipant {
			return
		}
	}

	notification := prepareActiveNotification(contentId, notifierId)
	notification.ContextChannelId = contextChannel.Id
	if err := notification.Upsert(); err != nil {
		c.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func isParticipant(accountId int64, c *socialapimodels.Channel) (bool, error) {
	cp := socialapimodels.NewChannelParticipant()
	cp.ChannelId = c.Id

	return cp.IsParticipant(accountId)
}

func (c *Controller) notifyOnce(contentId, notifierId int64) {
	notification := prepareActiveNotification(contentId, notifierId)
	if err := notification.Create(); err != nil {
		c.log.Error("An error occurred while notifying user %d: %s", notification.AccountId, err.Error())
	}
}

func prepareActiveNotification(contentId, notifierId int64) *models.Notification {
	n := newNotification(contentId, notifierId, time.Now().UTC())
	n.ActivatedAt = time.Now().UTC()

	return n
}

func (n *Controller) subscribe(contentId, notifierId int64, subscribedAt time.Time, c *socialapimodels.Channel) {
	nn := newNotification(contentId, notifierId, subscribedAt)
	nn.SubscribeOnly = true
	nn.ContextChannelId = c.Id
	if err := nn.Create(); err != nil {
		n.log.Error("An error occurred while subscribing user %d: %s", nn.AccountId, err.Error())
	}
}

func newNotification(contentId, notifierId int64, subscribedAt time.Time) *models.Notification {
	n := models.NewNotification()
	n.NotificationContentId = contentId
	n.AccountId = notifierId
	n.SubscribedAt = subscribedAt

	return n
}

func (c *Controller) CreateInteractionNotification(i *socialapimodels.Interaction) error {
	cm := socialapimodels.NewChannelMessage()
	if err := cm.ById(i.MessageId); err != nil {
		return err
	}

	// user likes her own message, so we bypass notification
	if cm.AccountId == i.AccountId {
		return nil
	}

	groupChannel, err := cm.FetchParentChannel()
	if err != nil {
		return err
	}

	isParticipant, err := isParticipant(cm.AccountId, groupChannel)
	if err != nil || !isParticipant {
		return err
	}

	in := models.NewInteractionNotification(i.TypeConstant)
	if cm.TypeConstant == socialapimodels.ChannelMessage_TYPE_POST {
		in.TargetId = i.MessageId
	} else {
		mr := socialapimodels.NewMessageReply()
		mr.ReplyId = i.MessageId

		cm, err := mr.FetchParent()
		if err != nil {
			return err
		}

		in.TargetId = cm.Id
	}

	in.MessageId = i.MessageId
	in.NotifierId = i.AccountId
	nc, err := models.CreateNotificationContent(in)
	if err != nil {
		return err
	}

	notification := models.NewNotification()
	notification.NotificationContentId = nc.Id
	notification.AccountId = cm.AccountId       // notify message owner
	notification.ActivatedAt = time.Now().UTC() // enables notification immediately
	notification.ContextChannelId = groupChannel.Id
	if err = notification.Upsert(); err != nil {
		return fmt.Errorf("An error occurred while notifying user %d: %s", cm.AccountId, err.Error())
	}

	return nil
}

func filterRepliers(repliers, mentionedUsers []int64) []int64 {
	mentionMap := map[int64]struct{}{}
	flattened := make([]int64, 0)
	if len(mentionedUsers) == 0 {
		return repliers
	}

	for _, user := range mentionedUsers {
		mentionMap[user] = struct{}{}
	}

	for _, replier := range repliers {
		if _, ok := mentionMap[replier]; !ok {
			flattened = append(flattened, replier)
		}
	}

	return flattened
}

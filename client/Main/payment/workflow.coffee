# This class is responsible of showing the payment modal.
# This workflow will decide if what to do next.
# No matter where you are instantiating this class,
# as long as you pass the view instance to this class
# it will emit necessary events when a substantial thing
# happens in the work flow.
#
# Necessary options when you instantiate it.
#
# planTitle  : string (see PaymentWorkflow.plans)
# monthPrice : int (e.g 1900 for $19)
# yearPrice  : int (e.g 19000 for $190)
# view       : KDView
class PaymentWorkflow extends KDController

  @interval:
    MONTH  : 'month'
    YEAR   : 'year'

  @plan          :
    FREE         : 'free'
    HOBBYIST     : 'hobbyist'
    DEVELOPER    : 'developer'
    PROFESSIONAL : 'professional'

  @isUpgrade: (current, selected) ->

    { FREE, HOBBYIST, DEVELOPER, PROFESSIONAL } = PaymentWorkflow.plan
    arr = [FREE, HOBBYIST, DEVELOPER, PROFESSIONAL]

    (arr.indexOf selected) > (arr.indexOf current)


  initialState: {}


  constructor: (options = {}, data) ->

    super options, data

    @state = @utils.extend @initialState, options.state

    @initPaymentProvider()
    @start()


  initPaymentProvider: ->

    return  if window.Stripe?

    options = tagName: 'script', attributes: { src: 'https://js.stripe.com/v2/' }
    document.head.appendChild (@providerScript = new KDCustomHTMLView options).getElement()

    repeater = KD.utils.repeat 500, =>

      return  unless Stripe?

      Stripe.setPublishableKey KD.config.stripe.token

      @modal.emit 'PaymentProviderLoaded', { provider: Stripe }
      window.clearInterval repeater


  start: ->

    {
      planTitle, monthPrice, yearPrice, reducedMonth, discount
    } = @getOptions()

    @state = @utils.extend @state, {
      planTitle, monthPrice, yearPrice, reducedMonth, discount
    }

    @modal = new PaymentModal { @state }
    @modal.on 'PaymentWorkflowFinished', @bound 'finish'
    @modal.on "PaymentSubmitted",        @bound 'handlePaymentSubmit'


  handlePaymentSubmit: (formData) ->

    {
      cardNumber, cardCVC, cardMonth,
      cardYear, planTitle, planInterval,
      currentPlan
    } = formData

    # Just because stripe validates both 2 digit
    # and 4 digit year, and different types of month
    # we are enforcing those, other than length problems
    # Stripe will take care of the rest. ~U
    cardYear  = null  if cardYear.length isnt 4
    cardMonth = null  if cardMonth.length isnt 2

    if currentPlan is PaymentWorkflow.plan.FREE

      Stripe.card.createToken {
        number    : cardNumber
        cvc       : cardCVC
        exp_month : cardMonth
        exp_year  : cardYear
      } , (status, response) =>

        if response.error
          return @modal.emit 'StripeRequestValidationFailed', response.error
          @modal.form.submitButton.hideLoader()

        token = response.id
        @subscribeToPlan planTitle, planInterval, token
    else
      @subscribeToPlan planTitle, planInterval, 'a'

    @state.currentPlan = planTitle


  subscribeToPlan: (planTitle, planInterval, token = 'a') ->
    { paymentController } = KD.singletons

    me = KD.whoami()
    me.fetchEmail (err, email) =>

      return KD.showError err  if err

      obj = { email }

      paymentController.subscribe token, planTitle, planInterval, obj, (err, result) =>
        @modal.form.submitButton.hideLoader()

        if err
        then @modal.emit 'PaymentFailed', err
        else @modal.emit 'PaymentSucceeded'


  finish: (state) ->

    { view } = @getOptions()

    @emit 'PaymentWorkflowFinishedSuccessfully', state

    view.state.currentPlan = state.currentPlan

    @modal.destroy()



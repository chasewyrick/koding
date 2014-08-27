do ->

  handleChannel = (type, slug, callback) ->

    {appManager} = KD.singletons
    callback    ?= (app) -> app.getView().open type, slug
    appManager.open 'Activity', callback


  KD.registerRoutes 'Activity',

    '/:name?/Activity/Public' : ({params: {name}}) -> handleChannel 'topic', 'public'

    '/:name?/Activity/Topic/:slug?' : ({params:{name, slug}, query}) ->
      if slug is 'public'
      then KD.singletons.router.handleRoute '/Activity/Public'
      else handleChannel 'topic', slug

    '/:name?/Activity/Post/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'post', slug

    '/:name?/Activity/Message/New' : ->
      handleChannel null, null, (app) -> app.getView().showNewMessageModal()

    '/:name?/Activity/Topic/All' : ({params:{name, slug}, query}) ->
      handleChannel null, null, (app) -> app.getView().showAllTopicsModal()

    '/:name?/Activity/Post/All' : ({params:{name, slug}, query}) ->
      handleChannel null, null, (app) -> app.getView().showAllConversationsModal()

    '/:name?/Activity/Message/:slug?' : ({params:{name, slug}, query}) ->
      handleChannel 'message', slug

    '/:name?/Activity/:slug' : ({params:{name, slug}, query}) ->
      handleChannel 'post', slug

    '/:name?/Activity' : ({params:{name, slug}, query}) ->
      # handle legacy topic routes
      if query.tagged?
        KD.getSingleton('router').handleRoute "/Activity/Topic/#{query.tagged}"
      else
        {router, appManager} = KD.singletons
        router.handleRoute '/Activity/Public'

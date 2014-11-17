onCollections ->

  class @CollectionsViewModel

    @constructor: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @alert_legend = ko.observable(false)
      @showingLegend = ko.observable(false)
      @fullscreen = ko.observable(false)
      @fullscreenExpanded = ko.observable(false)
      @selectedQuery = ko.observable()
      @currentSnapshot = ko.computed =>
        @currentCollection()?.currentSnapshot

    @findCollectionById: (id) -> (x for x in @collections() when x.id == parseInt id)[0]
    
    @refineFilters: ->
      @filters([])
      conditions = @selectedQuery()?.conditions ? []
      for condition in conditions
        if condition.field_id == 'update'
          if condition.field_value == 'last_hour'
            @filters.push(new FilterByLastHour())
          else if condition.field_value == 'last_day'
            @filters.push(new FilterByLastDay())
          else if condition.field_value == 'last_week'
            @filters.push(new FilterByLastWeek())
          else if condition.field_value == 'last_month'
            @filters.push(new FilterByLastMonth())
        else if condition.field_id == 'location_missing'
          @filters.push(new FilterByLocationMissing())
        else
          field = @currentCollection().findFieldByEsCode(condition.field_id)
          if field.kind == 'text' || field.kind == 'phone' || field.kind == 'email' || field.kind == 'user'
            @filters.push(new FilterByTextProperty(field, condition.operator, condition.field_value))
          else if field.kind == 'numeric'
            @filters.push(new FilterByNumericProperty(field, condition.operator, condition.field_value))
          else if field.kind == 'yes_no'
            @filters.push(new FilterByYesNoProperty(field, condition.field_value))
          else if field.kind == 'date'
            @filters.push(new FilterByDateProperty(field, condition.operator, condition.field_date_from, condition.field_date_to))
          else if field.kind == 'hierarchy'
            @filters.push(new FilterByHierarchyProperty(field, "under", condition.field_value))
          else if field.kind == 'select_one' || field.kind == 'select_many'
            @filters.push(new FilterBySelectProperty(field, condition.field_value))
          else if field.kind == 'site'
            id = @currentCollection().findSiteIdByName(condition.field_value)
            @filters.push(new FilterBySiteProperty(field, condition.operator, condition.field_value, id))

    @goToRoot: ->
      @filters([])
      @selectedQuery(null)
      @queryParams = $.url().param()
      @currentCollection(null)
      @showingAlert(false)
      @cancelFilterAlertedSites()
      @exitSite() if @editingSite()
      @unselectSite() if @selectedSite()
      @search('')
      @lastSearch(null)
      
      @sort(null)
      @sortDirection(null)
      @groupBy(@defaultGroupBy)
      initialized = @initMap()
      @reloadMapSites() unless initialized
      @refreshTimeago()
      @makeFixedHeaderTable()
      @hideRefindAlertOnMap()
      # @setThresholds()

      @rewriteUrl()

      $('.BreadCrumb').load("/collections/breadcrumbs", {})

      @getAlertedCollections()
      window.setTimeout(window.adjustContainerSize, 100)

      # Return undefined because otherwise some browsers (i.e. Miss Firefox)
      # would render the Object returned when called from a 'javascript:___'
      # value in an href (and this is done in the breadcrumb links).
      undefined

    @deleteMembership: () =>
      alert 'delete'

    @enterCollection: (collection) ->
      if @showingAlert()
        return if !collection.checked()
      @queryParams = $.url().param()

      # collection may be a collection object (in most of the cases)
      # or a string representing the collection id (if the collection is being loaded from the url)
      if typeof collection == 'string'
        collection = @findCollectionById parseInt(collection)

      @currentCollection collection
      @unselectSite() if @selectedSite()
      @exitSite() if @editingSite()   

      if @showingAlert()
        $.get "/collections/#{@currentCollection().id}/sites_by_term.json", _alert: true, (sites) =>
          @currentCollection().allSites(sites)
          window.adjustContainerSize()
          
      else
        $.get "/collections/#{@currentCollection().id}/sites_by_term.json", (sites) =>
          @currentCollection().allSites(sites)
          window.adjustContainerSize()

      initialized = @initMap()
      collection.panToPosition(true) unless initialized

      collection.fetchSitesMembership()
      collection.fetchQueries()
      collection.fetchFields =>
        if @processingURL
          @processURL()
        else
          @ignorePerformSearchOrHierarchy = false
          @performSearchOrHierarchy()
          @refreshTimeago()
          @makeFixedHeaderTable()
          @rewriteUrl()

        window.adjustContainerSize()
      $('.BreadCrumb').load("/collections/breadcrumbs", { collection_id: collection.id })
      window.adjustContainerSize()
      window.model.updateSitesInfo()
      @showRefindAlertOnMap()
      @setThresholds()
      @filters([])

    @editCollection: (collection) -> window.location = "/collections/#{collection.id}"

    @openDialog:  ->
      $(".rm-dialog").rmDialog().show()
      $("#rm-colllection_id").val(@currentCollection().id)

    @tooglefullscreen: ->
      if !@fullscreen()
        @fullscreen(true)
        $("body").addClass("fullscreen")
        $(".ffullscreen").addClass("frestore")
        $(".ffullscreen").removeClass("ffullscreen")
        $('.expand-collapse_button').show()
        $(".expand-collapse_button").addClass("oleftcollapse")
        $(".expand-collapse_button").removeClass("oleftexpand")
        window.adjustContainerSize()
        @reloadMapSites()
      else
        @fullscreen(false)
        @fullscreenExpanded(false)
        $("body").removeClass("fullscreen")
        $(".frestore").addClass("ffullscreen")
        $(".frestore").removeClass("frestore")
        $('#collections-main .left').show()
        $('.expand-collapse_button').hide()
        window.adjustContainerSize()
        @reloadMapSites()
      @makeFixedHeaderTable()

      window.setTimeout(window.adjustContainerSize, 200)

    @toogleExpandFullScreen: ->
      if @fullscreen() && !@fullscreenExpanded()
        @fullscreenExpanded(true)
        $('#collections-main .left').hide()
        window.adjustContainerSize()
        $(".oleftcollapse").addClass("oleftexpand")
        $(".oleftcollapse").removeClass("oleftcollapse")
        @reloadMapSites()

      else
        if @fullscreen() && @fullscreenExpanded()
          @fullscreenExpanded(false)
          $('#collections-main .left').show()
          window.adjustContainerSize()
          $(".oleftexpand").addClass("oleftcollapse")
          $(".oleleftexpand").removeClass("oleftexpand")
          @reloadMapSites()

    @hideRefindAlertOnMap: ->
      $('#sites_whitout_location_alert').hide()

    @showRefindAlertOnMap: ->
      $('#sites_whitout_location_alert').show()

    @createCollection: -> window.location = "/collections/new"

    @setThresholds: ->
      if @currentCollection()
        @showingLegend(false)
        @currentCollection().thresholds([])
        @currentCollection().showLegend(false) 
        $.get "/plugin/alerts/collections/#{@currentCollection().id}/thresholds.json", (data) =>  
          thresholds = @currentCollection().fetchThresholds(data)     
          @currentCollection().thresholds(@currentCollection().findSitesByThresholds(thresholds))
      else
        $.get "/plugin/alerts/thresholds.json", (data) =>
          for collection in @collections()
            if collection.checked() == true && collection.sites().length > 0
              thresholds = collection.fetchThresholds(data)
              collection.thresholds(collection.findSitesByThresholds(thresholds))
              thresholds = []
          @showLegendState()

    @showLegendState: ->
      for collection in @collections()
        if collection.checked() == true && collection.showLegend()
          @showingLegend(true)
          break
        else
          @showingLegend(false)

    @toggleAlertLegend: ->
      if @showingLegend() == true
        if @alert_legend() == true
          @alert_legend(false)
        else
          @alert_legend(true)

    @hideDatePicker: ->
      $("input").datepicker "hide"
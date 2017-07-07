onCollections ->
  class @FieldLocation
    @constructorFieldLocation: (data) ->
      @locations = if data.config?.locations?
                    $.map data.config.locations, (x) => new Location x
                   else
                    []
      @resultLocations = ko.observableArray([])
      @maximumSearchLength = data.config?.maximumSearchLength

    @labelForLocation: (code) ->
      for option in @resultLocations()
        if option.code == code
          return option.name
      ''

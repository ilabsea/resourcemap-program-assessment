onLayers ->
  class @Field_location extends @FieldImpl
    constructor: (field) ->
      super(field)
      @maximumSearchLength = ko.observable(field?.config?.maximumSearchLength)
      @uploadingLocation = ko.observable(false)
      @errorUploadingLocation = ko.observable(false)
      @locations = if field?.config?.locations
                    ko.observableArray($.map(field?.config?.locations, (x) -> new Location(x)))
                   else
                    ko.observableArray()

      @maximumSearchLengthError = ko.computed =>
        if @maximumSearchLength() && @maximumSearchLength().length >0
          null
        else
          window.t('javascripts.layers.fields.errors.the_field') + " #{@field.fieldErrorDescription()} " + window.t('javascripts.layers.fields.errors.is_missing_a_maximum_search_length')
      @missingFileLocationError = ko.computed =>
        if @locations() && @locations().length > 0
          null
        else
          window.t('javascripts.layers.fields.errors.the_field') + " #{@field.fieldErrorDescription()} "+ window.t('javascripts.layers.fields.errors.is_missing_location_file')

      @error = ko.computed =>
        @missingFileLocationError() || @maximumSearchLengthError()

    setLocation: (locations) =>
      @locations($.map(locations, (x) -> new Location(x)))
      @uploadingLocation(false)
      @errorUploadingLocation(false)

    toJSON: (json)=>
      json.config = {locations: $.map(@locations(), (x) ->  x.toJSON()), maximumSearchLength: @maximumSearchLength(),field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

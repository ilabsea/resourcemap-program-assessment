onLayers ->
  class @FieldValidation
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @field_id = ko.observableArray([data?.field_id])
      @condition_type = ko.observable(data?.condition_type)
      @editing = ko.observable(false)

    toJSON: =>
      id: @id()
      field_id: @field_id()
      condition_type: @condition_type()
onLayers ->
  class @FieldLogic
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @value = ko.observable(data?.value)
      if data and data.selected_options?
        @selected_options = ko.observableArray $.map(data?.selected_options, (x) -> new FieldLogicValue(x))
      else
        @selected_options = ko.observableArray([])
      @label = ko.observable(data?.label)

      @field_id = if (typeof data?.field_id == 'object') && data?.field_id?.length > 0
                    ko.observable(data?.field_id[0])
                  else
                    ko.observable(data?.field_id)

      @condition_type = ko.observable(data?.condition_type)
      @editing = ko.observable(false)
      @valid = ko.observable(true)
      @error = ko.observable()
      @is_numeric = ko.computed => return @fieldType(@field_id()) == "numeric"


    toJSON: =>
      id: @id()
      value: @value()
      selected_options: $.map(@selected_options(), (x) -> x.toJSON())
      label: @label()
      field_id: @field_id()
      condition_type: @condition_type()

    fieldType: (field_id)=>
      if window.model
        for field in window.model.fieldList()
          if parseInt(field.id()) == parseInt(field_id)
            return field.kind()

    fieldName: (field_id)=>
      if window.model
        for field in window.model.fieldList()
          if parseInt(field.id()) == parseInt(field_id)
            return field.name()

    fieldId: (field_name)=>
      if window.model
        for field in window.model.fieldList()
          if field.name() == field_name
            return field.id()

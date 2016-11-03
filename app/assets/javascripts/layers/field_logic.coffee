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
      @field_id = ko.observableArray([data?.field_id])
      @condition_type = ko.observable(data?.condition_type)
      @editing = ko.observable(false)
      @valid = ko.observable(true)
      @error = ko.observable()
      @is_numeric= ko.observable(false)
      @field_id.subscribe =>
        $.map(model.layers(), (x, index) =>
          fields = x.support_skiplogic_fields()
          $.map(fields, (f) =>
            if f.id == @field_id()[0]
              if f.kind == "numeric"
                @is_numeric(true)
              else
                @is_numeric(false)
          )
        )

    toJSON: =>
      id: @id()
      value: @value()
      selected_options: $.map(@selected_options(), (x) -> x.toJSON())
      label: @label()
      field_id: @field_id()
      condition_type: @condition_type()
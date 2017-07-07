onLayers ->
  class @Field_select_many extends @FieldSelect
    constructor: (field) ->
      super(field)
      @selected_field_logics = if field.config?.field_logics?
        ko.observableArray(
          $.map(field.config.field_logics, (x) -> new FieldLogic(x))
        )
      else
        ko.observableArray()

    add_field_logic: (field_logic) =>
      @field_logics.push field_logic

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId,field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

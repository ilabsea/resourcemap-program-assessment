onLayers ->
  class @Field_select_one extends @FieldSelect
    constructor: (field) ->
      super(field)

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId,field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

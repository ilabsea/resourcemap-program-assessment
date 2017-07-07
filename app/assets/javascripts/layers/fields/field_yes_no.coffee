onLayers ->
  class @Field_yes_no extends @FieldImpl
    constructor: (field) ->
      super(field)

      @field_logics = if field.config?.field_logics?
                        ko.observableArray(
                          $.map(field.config.field_logics, (x) -> new FieldLogic(x))
                        )
                      else
                        ko.observableArray()

    validFieldLogic: =>
      @field_logics().filter (field_logic) -> typeof field_logic.field_id() isnt 'undefined'

    toJSON: (json) =>
      json.config = {field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

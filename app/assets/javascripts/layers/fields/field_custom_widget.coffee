onLayers ->
  class @Field_custom_widget extends @FieldImpl
    constructor: (field) ->
      super(field)
      @widgetContent = ko.observable field?.config?.widget_content
    toJSON: (json) =>
      json.config = { widget_content: @widgetContent(),field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

onLayers ->
  class @Field_text extends @FieldImpl
    constructor: (field) ->
      super(field)
      @attributes = if field.metadata?
                      ko.observableArray($.map(field.metadata, (x) -> new Attribute(x)))
                    else
                      ko.observableArray()
      @advancedExpanded = ko.observable false

    toggleAdvancedExpanded: =>
      @advancedExpanded(not @advancedExpanded())

    addAttribute: (attribute) =>
      @attributes.push attribute

    toJSON: (json) =>
      json.metadata = $.map(@attributes(), (x) -> x.toJSON())
      json.config = { field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}


  class @Field_email extends @Field_text

  class @Field_phone extends @Field_text

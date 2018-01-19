onLayers ->
  class @Field_calculation extends @FieldImpl
    constructor: (field) ->
      super(field)
      @allowsDecimals = ko.observable field?.config?.allows_decimals == 'true'
      @digitsPrecision = ko.observable field?.config?.digits_precision
      @dependent_fields = if field.config?.dependent_fields?
                            ko.observableArray(
                              $.map(field.config.dependent_fields, (x) -> new FieldDependant(x))
                            )
                          else
                            ko.observableArray()
      @codeCalculation = ko.observable field.config?.code_calculation ? ""
      @autoCompleteValue = ko.observable()

    selectField: (event, ui) =>
      $(event.target).val("")
      id = ui.item.value
      fields = window.model.fieldList().filter (f) -> "#{f.id()}" == "#{id}"
      if fields.length > 0
        @addDependentField(fields[0])
      return false

    addDependentField: (field) =>
      fields = @dependent_fields().filter (f) -> "#{f.id()}" == "#{field.id()}"
      if fields.length == 0
        field.editableCode(false)
        @dependent_fields.push(new FieldDependant(field.toJSON()))

    removeDependentField: (field) =>
      @dependent_fields.remove field

    addFieldToCodeCalculation: (field) =>
      @codeCalculation(@codeCalculation() + '${' + field.code() + "}")
    toJSON: (json) =>
      json.config = {digits_precision: @digitsPrecision(), allows_decimals: @allowsDecimals(), code_calculation: @codeCalculation(), dependent_fields: $.map(@dependent_fields(), (x) ->  x.toJSON())}

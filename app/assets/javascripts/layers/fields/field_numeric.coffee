onLayers ->
  class @Field_numeric extends @FieldImpl
    constructor: (field) ->
      super(field)

      @allowsDecimals = ko.observable field?.config?.allows_decimals == 'true'
      @digitsPrecision = ko.observable field?.config?.digits_precision
      @is_enable_range = ko.observable field?.is_enable_range ? false
      @minimum = ko.observable field?.config?.range?.minimum
      @maximum = ko.observable field?.config?.range?.maximum
      @error = ko.computed =>
        if (@is_enable_range() && @minimum() && @minimum()) && parseInt(@minimum()) > parseInt(@maximum())
          "Invalid range, maximum must greater than minimum"

      @field_validations = if field.config?.field_validations?
                        ko.observableArray(
                          $.map(field.config.field_validations, (x) -> new FieldValidation(x))
                        )
                      else
                        ko.observableArray([])

    validate_number_only: (field,event) =>
      if event.keyCode > 31 && (event.keyCode < 48 || event.keyCode > 57)
        return false
      return true

    toJSON: (json) =>
      json.is_enable_range = @is_enable_range()
      json.config = { digits_precision: @digitsPrecision(), allows_decimals: @allowsDecimals(), range: {minimum: @minimum(), maximum: @maximum()}, field_logics: $.map(@field_logics(), (x) ->  x.toJSON()), field_validations: $.map(@field_validations(), (x) ->  x.toJSON())}
      return json


    saveFieldValidation: (field_validation) =>
      if !field_validation.id()?
        if @field_validations().length > 0
          id = @field_validations()[@field_validations().length - 1].id() + 1
        else
          id = 0
        field_validation.id id
        @field_validations.push field_validation

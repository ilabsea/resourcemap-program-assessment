onCollections ->
  class @FieldNumeric
    @constructorFieldNumeric: (data) ->
      @keyType = if @allowsDecimals() then 'decimal' else 'integer'
      @digitsPrecision = data?.config?.digits_precision
      @range = if data.config?.range?.minimum? || data.config?.range?.maximum?
                data.config?.range
      @is_enable_custom_validation = ko.observable data?.is_enable_custom_validation ? false
      @configCustomValidations = ko.observable data?.config?.field_validations

onCollections ->
  class @FieldValidator
    constructor: (field) ->
      @field = field

    validateMandatory: =>
      if @field.is_mandatory()
        if !@field.value() || @field.value().length == 0
          @field.errorMessage(window.t('javascripts.collections.validator.this_field_is_required'))
        else
          @field.errorMessage('')
      return

    validateFormat: =>
      if @field.value()
        if @field.kind == 'date'
          if @isValidDate() then @field.errorMessage('') else @field.errorMessage(window.t('javascripts.collections.validator.invalid_field_format'))
        else if @field.kind == 'email'
          if(@isValidEmail()) then @field.errorMessage('') else @field.errorMessage(window.t('javascripts.collections.validator.invalid_field_format'))
      return

    validateRangeAndDigitsPrecision: =>
      if @field.kind == 'numeric'
        @isValidateRange()
        @isValidateDigitsPrecision()

    validateCustomValidation: =>
      if @field.kind == 'numeric' && window.model.editingSite()
        if  @field.is_enable_custom_validation() && @field.configCustomValidations()
          $.map(@field.configCustomValidations(), (f) =>
            field = window.model.editingSite().findFieldByEsCode(f.field_id[0])
            if field
              compareValue = field.value()
              if(!compareValue)
                compareValue = 0

              @generateErrorMessage(f, @field, compareValue, field.name)
          )

        if @field.config().compare_custom_validations
          $.map(@field.config().compare_custom_validations, (v) =>
            field = window.model.editingSite().findFieldByEsCode(v.field_id)

            compareValue = @field.value()
            if(!compareValue)
              compareValue = 0

            @generateErrorMessage(v, field, compareValue, @field.name)
          )

    generateErrorMessage: (fieldConfig, validateField, compareValue, fieldName)=>
      compareValue = parseFloat(compareValue)
      fieldValue = parseFloat(validateField.value())
      if fieldConfig.condition_type == '='
        if fieldValue != compareValue
          validateField.errorMessage(window.t('javascripts.collections.validator.value_must_be_equal_to_field') + fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '<'
        if fieldValue >= compareValue
          validateField.errorMessage(window.t('javascripts.collections.validator.value_must_be_less_than_field') + fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '>'
        if fieldValue <= compareValue
          validateField.errorMessage(window.t('javascripts.collections.validator.value_must_be_greater_than_field') + fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '>='
        if fieldValue < compareValue
          validateField.errorMessage(window.t('javascripts.collections.validator.value_must_be_greater_than_and_equal_to_field') + fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '<='
        if fieldValue > compareValue
          validateField.errorMessage(window.t('javascripts.collections.validator.value_must_be_less_than_and_equal_to_field') + fieldName)
        else
          validateField.errorMessage('')

    isValidateDigitsPrecision: =>
      if @field.digitsPrecision and @field.value() != ""
        value = parseInt(@field.value() * Math.pow(10, parseInt(@field.digitsPrecision))) / Math.pow(10, parseInt(@field.digitsPrecision))
        if value then @field.value(value) else @field.value('')

    isValidateRange: =>
      if @field.range and @field.value()
        if @field.range.minimum && @field.range.maximum
          if parseFloat(@field.value()) >= parseFloat(@field.range.minimum) && parseFloat(@field.value()) <= parseFloat(@field.range.maximum)
            @field.errorMessage('')
          else
            @field.errorMessage(window.t('javascripts.collections.validator.value_must_be_in_the_range_of', {min: @field.range.minimum, max: @field.range.maximum}))
        else
          if @field.range.maximum
            if parseFloat(@field.value()) <= parseFloat(@field.range.maximum)
              @field.errorMessage('')
            else
              @field.errorMessage(window.t('javascripts.collections.validator.value_must_be_less_than_or_equal_to') +@field.range.maximum)
            return

          if @field.range.minimum
            if parseFloat(@field.value()) >= parseFloat(@field.range.minimum)
              @field.errorMessage('')
            else
              @field.errorMessage(window.t('javascripts.collections.validator.value_must_be_greater_than_or_equal_to') +@field.range.minimum)
            return

    isValidDate: =>
      regEx = /^\d{2}\/\d{2}\/\d{4}$/
      return false if !@field.value().match(regEx)

      dateParts = @field.value().split("/");
      dateStr = dateParts[2]+'-'+dateParts[1]+'-'+dateParts[0]
      d = new Date(dateStr);
      return false if !d.getTime() and d.getTime() != 0
      return (d.toISOString().slice(0, 10) == dateStr)

    isValidEmail: =>
      regExp = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
      return regExp.test(@field.value().trim())

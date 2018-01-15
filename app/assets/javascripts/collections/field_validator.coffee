onCollections ->
  class @FieldValidator
    constructor: (field) ->
      @field = field

    validateMandatory: =>
      if @field.is_mandatory()
        if !@field.value() || @field.value().length == 0
          @field.errorMessage('This field is required !')
        else
          @field.errorMessage('')
      return

    validateFormat: =>
      if @field.value()
        if @field.kind == 'date'
          if @isValidDate() then @field.errorMessage('') else @field.errorMessage('Invalid field format')
        else if @field.kind == 'email'
          if(@isValidEmail()) then @field.errorMessage('') else @field.errorMessage('Invalid field format')
      return

    validateRangeAndDigitsPrecision: =>
      @isValidateRange()
      @isValidateDigitsPrecision()

    validateCustomValidation: =>
      if window.model.editingSite()
        if @field.is_enable_custom_validation()
          $.map(@field.configCustomValidations(), (f) =>
            field = window.model.editingSite().findFieldByEsCode(f.field_id[0])
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
          validateField.errorMessage('Invalid value, value must be equal to field '+ fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '<'
        if fieldValue >= compareValue
          validateField.errorMessage('Invalid value, value must be less than field '+ fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '>'
        if fieldValue <= compareValue
          validateField.errorMessage('Invalid value, value must be greater than field '+ fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '>='
        if fieldValue < compareValue
          validateField.errorMessage('Invalid value, value must be greater than and equal to field '+ fieldName)
        else
          validateField.errorMessage('')
      else if fieldConfig.condition_type == '<='
        if fieldValue > compareValue
          validateField.errorMessage('Invalid value, value must be less than and equal to field '+ fieldName)
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
            @field.errorMessage('Invalid value, value must be in the range of ('+@field.range.minimum+'-'+@field.range.maximum+")")
        else
          if @field.range.maximum
            if parseFloat(@field.value()) <= parseFloat(@field.range.maximum)
              @field.errorMessage('')
            else
              @field.errorMessage('Invalid value, value must be less than or equal '+@field.range.maximum)
            return

          if @field.range.minimum
            if parseFloat(@field.value()) >= parseFloat(@field.range.minimum)
              @field.errorMessage('')
            else
              @field.errorMessage('Invalid value, value must be greater than or equal '+@field.range.minimum)
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

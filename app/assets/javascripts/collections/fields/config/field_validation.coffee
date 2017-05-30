onCollections ->

  class @FieldValidation

    @constructorFieldValidation: (data) ->
      @digitsPrecision = data?.config?.digits_precision
      @range = if data.config?.range?.minimum? || data.config?.range?.maximum?
                data.config?.range
      @is_enable_custom_validation = ko.observable data?.is_enable_custom_validation ? false

      @hasValue = ko.computed =>
        if @kind == 'yes_no'
          true
        else if @kind == 'select_many'
          @value() && @value().length > 0
        else if @kind == 'numeric'
          @value() != '' && @value() != null && @value() != undefined
        else
          @value()

    @validateRangeAndCustomeValidation: ->
      @validateRange()
      @validateCustomValidation()

    @validateRangeAndDigitsPrecision: ->
      @validateRange()
      @validateDigitsPrecision()

    @validateDigitsPrecision: ->
      if @digitsPrecision and @value() != ""
        @value(parseInt(@value() * Math.pow(10, parseInt(@digitsPrecision))) / Math.pow(10, parseInt(@digitsPrecision)))

    @validateRange: ->
      if @range
        if @range.minimum && @range.maximum
          if parseFloat(@value()) >= parseFloat(@range.minimum) && parseFloat(@value()) <= parseFloat(@range.maximum)
            @errorMessage('')
          else
            @errorMessage('Invalid value, value must be in the range of ('+@range.minimum+'-'+@range.maximum+")")
        else
          if @range.maximum
            if parseFloat(@value()) <= parseFloat(@range.maximum)
              @errorMessage('')
            else
              @errorMessage('Invalid value, value must be less than or equal '+@range.maximum)
            return

          if @range.minimum
            if parseFloat(@value()) >= parseFloat(@range.minimum)
              @errorMessage('')
            else
              @errorMessage('Invalid value, value must be greater than or equal '+@range.minimum)
            return

    @validateCustomValidation: ->
      if @is_enable_custom_validation()
        $.map(@, (f) =>
          if f.esCode == field_id
            flag = true
          if flag
            @enableField f
            return
        )
    @validate_integer_only: (keyCode) ->
      value = $('#'+@kind+'-input-'+@code).val()
      if value == null || value == ""
        if(keyCode == 189 || keyCode == 173) && (@preKeyCode != 189 || @preKeyCode == null || @preKeyCode == 173) #allow '-' for both chrome & firefox
          @preKeyCode = keyCode
          return true
      else
        if(keyCode == 189 || keyCode == 173) && value.charAt(0) != '-'
          @preKeyCode = keyCode
          return true
      if keyCode > 31 && (keyCode < 48 || keyCode > 57) && (keyCode != 8 && keyCode != 46) && keyCode != 37 && keyCode != 39  #allow right and left arrow key
        return false
      else
        @preKeyCode = keyCode
        return true

    @validate_digit: (keyCode) ->
      value = $('#'+@kind+'-input-'+@code).val()
      #check digit precision
      valueAfterSplit = value.split '.'
      if valueAfterSplit.length >= 2
        decimalValue = valueAfterSplit[1]
        ele = document.getElementById(@kind+"-input-"+@code)
        pos = $.caretPosition(ele)
        if @digitsPrecision
          if keyCode == 8 || keyCode == 9 || keyCode == 173 || (keyCode >= 37 && keyCode <=40)
            return true
          if pos <= value.indexOf('.')
            return true
          if decimalValue.length < parseInt(@digitsPrecision)
            return true
          if decimalValue.length >= parseInt(@digitsPrecision)
            return false

      return true

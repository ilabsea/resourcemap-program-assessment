onCollections ->
  class @FieldView
    constructor: (field) ->
      @field = field

    domObject: ->
      if(@field.isForCustomWidget())
        @fieldUI = $('#custom-widget-' + @field.code)
      else
        @fieldUI = $('#'+@field.kind+'-input-' + @field.code)

      return @fieldUI

    getValue: ->
      value = @field.value()
      if value
        if @field.kind == 'select_one'
          value = @valueForSelectOne(value)
        return value
      else
        if @field.kind == 'numeric'
          return 0
        else
          return ''


    setValue: (value)->
      if (@field.allowsDecimals() && !isNaN(value))
        digitsPrecision = @field.digitsPrecision
        value = parseFloat(value)
        if (digitsPrecision)
          value = Number(value.toFixed(parseInt(digitsPrecision)))
      if ((typeof (value) == "string" && value.indexOf("NaN") > -1))
        value = value.replace("NaN", "");
      else if (typeof (value) == "number" && isNaN(value))
        value = "";
      $fieldUI = if @fieldUI then @fieldUI else @domObject()
      @field.value(value)
      return $fieldUI.val(value)

    valueForSelectOne: (value) ->
      selectedOptions = @field.options.filter((option) => option.id == value)
      if selectedOptions.length > 0
        return "'"+selectedOptions[0].code+"'"
      else
        return ''

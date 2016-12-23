onCollections ->
  class @FieldView
    constructor: (field) ->
      @field = field

    domObject: ->
      @fieldUI = $('#'+@field.kind+'-input-' + @field.code)
      return @fieldUI

    getValue: ->
      return @field.value()

    setValue: (value)->
      if (@field.allowsDecimals() && !isNaN(value))
        digitsPrecision = field.digitsPrecision
        if (digitsPrecision)
          value = parseFloat(value)
          value = Number(value.toFixed(parseInt(digitsPrecision)))
      if ((typeof (value) == "string" && value.indexOf("NaN") > -1))
        value = value.replace("NaN", "");
      else if (typeof (value) == "number" && isNaN(value))
        value = "";
      $fieldUI = if @fieldUI then @fieldUI else @domObject()
      @field.value(value)
      return $fieldUI.val(value)

onCollections ->
  class @FieldLogic
    constructor: (data) ->
      @id = data?.id
      @value = data?.value
      @label = data?.label
      @field_id = data?.field_id
      if data and data.selected_options?
        @selected_options = $.map(data?.selected_options, (x) -> new FieldLogicValue(x))
      else
        @selected_options = []
      @condition_type = data?.condition_type || "all"

    parseYesNoFieldLogicValue: =>
      fieldLogicValue = @value.toString()
      if parseInt(fieldLogicValue) == 1 or fieldLogicValue.toUpperCase() == 'Y' or fieldLogicValue.toUpperCase() == 'YES'
        return 1
      return 0

    isSkip: (field) ->
      fieldValue = @parseForSkipValue(field)
      fieldLogicValue = @value
      switch @condition_type
        when "<" then parseFloat(fieldValue) < parseFloat(fieldLogicValue)
        when "<=" then parseFloat(fieldValue) >= parseFloat(fieldLogicValue)
        when ">" then parseFloat(fieldValue) > parseFloat(fieldLogicValue)
        when ">=" then parseFloat(fieldValue) >= parseFloat(fieldLogicValue)
        when "!=" then fieldValue != fieldLogicValue
        when "="
          match = false
          if field.kind == 'yes_no'
            fieldLogicValue = @parseYesNoFieldLogicValue()
            return (fieldValue == fieldLogicValue)
          else if field.kind == 'numeric'
            return (fieldValue == fieldLogicValue)
          else if field.kind == 'select_one'
            return (fieldValue?.toString() == fieldLogicValue?.toString())
          else if field.kind == 'select_many'
            arrLogicValue = fieldLogicValue.split(",")
            return @compareTwoArray(fieldValue, arrLogicValue)

    parseForSkipValue: (field)=>
      value = field.value()
      switch field.kind
        when "yes_no"
          value = if value then 1 else 0
        when "numeric"
          value = if value != null or value != undefined then value else null
        when "select_one"
          if value
            converted_value = $.map field.options, (x) => x.code if x.id == value
            value = converted_value[0] if converted_value.length > 0
          else
            value = null
        when "select_many"
          if value
            value = $.map field.options, (x) => x.code if value.includes(x.id)
          else
            value = []
      return value

    compareTwoArray: (arr1, arr2) =>
      status = true
      if arr1.length == arr2.length
        $.map(arr1, (el1) =>
          unless arr2.includes(el1)
            status = false
        )
      else
        status = false
      return status

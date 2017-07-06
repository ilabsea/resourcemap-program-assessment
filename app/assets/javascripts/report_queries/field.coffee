onReportQueries ->
  class @Field
    constructor: (layer, data) ->
      @layer = layer
      @id = data?.id
      @name = data?.name
      @code = data?.code
      @kind = data?.kind
      @config = data?.config
      @metadata = data?.metadata
      @is_mandatory = data?.is_mandatory
      @value = ko.observable(data?.value)
      @kind_titleize = ko.computed =>
        (@kind.split(/_/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      @ord = data?.ord
      @isInputField = ko.computed =>
        inputType = ['text', 'calculation', 'email', 'phone']
        if inputType.includes?(@kind) then true else false

      if @kind == 'hierarchy'
        @hierarchy = data.config?.hierarchy

      @buildHierarchyItems() if @hierarchy?


    buildHierarchyItems: =>
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))

    labelFor: (id) =>
      for option in @config.options
        if option.id == parseInt(id)
          return option.label
      null

    labelForLocation: (code) =>
      for option in @config.locations
        if option.code == code
          return option.name
      ''

    toJSON: =>
      @code = @code.trim()
      json =
        id: @id
        name: @name
        code: @code
        kind: @kind
        ord: @ord
        layer_id: @layer.id
        is_mandatory: @is_mandatory
      json

    validateFormat: (field,event) =>
      if @config.allows_decimals
        return @validate_decimal_only(event.keyCode)
      else
        return @validate_integer_only(event.keyCode)
      return trues

    validate_integer_only: (keyCode) =>
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

    validate_decimal_only: (keyCode) =>
      value = $('#'+@kind+'-input-'+@code).val()
      if (value == null || value == "") && (keyCode == 229 || keyCode == 190) #prevent dot at the beginning
        return false
      if (keyCode != 8 && keyCode != 46 && keyCode != 173) && (keyCode != 190 || value.indexOf('.') != -1) && (keyCode < 48 || keyCode > 57) #prevent multiple dot
        return false
      else
        return true

onQueries ->
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
      if @kind == 'hierarchy'
        @hierarchy = data.config?.hierarchy
        @parentHierarchyFieldId = data.config?.parent_hierarchy_field_id
        @isEnableDependancyHierarchy = data?.is_enable_dependancy_hierarchy
        @dependentHierarchyItemList = ko.observableArray(new FieldDependant(@).options())

      @buildHierarchyItems() if @hierarchy?
      @valueUI =  ko.computed
       read: =>  @valueUIFor(@value())
       write: (value) =>
         @value(@valueUIFrom(value))

    buildHierarchyItems: =>
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: '(no value)'})

    valueUIFor: (value) =>
      if @kind == 'yes_no'
        if value then 'yes' else 'no'
      else if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else
        if value then value else ''

    valueUIFrom: (value) =>
      if @kind == 'site'
        # Return site_id or "" if the id for this name is not found (deleting the value or invalid value)
        window.model.currentCollection()?.findSiteIdByName(value) || ""
      else
        value

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

    hierarchySet: (field=@, fields=[])=>
      if field.isEnableDependancyHierarchy == true && field.parentHierarchyFieldId == ''
        fields.push field
        return fields
      else
        parentField = @layer.findFieldById(field.parentHierarchyFieldId)
        @hierarchySet(parentField, fields)
        fields.push field
        return fields

    updateDependentFieldsHierarchyItemList: (field)=>
      if @isDependentFieldHierarchy && field
        return (new FieldDependant(field).updateDependentFieldsHierarchyItemList())
      else
        return []

    isDependentFieldHierarchy: =>
      return @kind == 'hierarchy' && @isEnableDependancyHierarchy

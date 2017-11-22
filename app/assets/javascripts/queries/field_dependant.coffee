onQueries ->
  class @FieldDependant
    constructor: (field) ->
      @field = field

    options: =>
      if @field.isDependentFieldHierarchy
        if @field.parentHierarchyFieldId == ''
          return @field.hierarchy

    children: =>
      children = []
      for layer in model.layers()
        for field in layer.fields
          if field.isEnableDependancyHierarchy && "#{field.parentHierarchyFieldId}" == "#{@field.id}"
            children.push field
      return children

    dependentHierarchyItemList: (fieldHierarchyItems) =>
      for item in fieldHierarchyItems
        if "#{item.id}" == "#{@field.value()}"
          return item.fieldHierarchyItems

      for item in fieldHierarchyItems
        if item.fieldHierarchyItems.length > 0
          dependentList = @dependentHierarchyItemList(item.fieldHierarchyItems)
          if dependentList?.length > 0
            return dependentList

    updateDependentFieldsHierarchyItemList: =>
      for field in @children()
        items = @dependentHierarchyItemList(field.fieldHierarchyItems())
        result = items?.map((item) -> {id: item.id, name: item.name}) ? []
        field.dependentHierarchyItemList(result)

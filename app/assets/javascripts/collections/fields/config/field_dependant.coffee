onCollections ->
  class @FieldDependant
    constructor: (site, field) ->
      @site = site
      @field = field

    children: =>
      children = []
      for field in @site.fields()
        if field.is_enable_dependancy_hierarchy() && "#{field.parentHierarchyFieldId}" == "#{@field.esCode}"
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

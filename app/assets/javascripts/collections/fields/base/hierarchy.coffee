onCollections ->
  class @FieldHierarchy
    @constructorFieldHierarchy: (data) ->
      @hierarchy = data.config?.hierarchy
      @buildHierarchyItems() if @hierarchy?
      @parentHierarchyFieldId = data.config?.parent_hierarchy_field_id
      @dependentHierarchyItemList = ko.observableArray(@initDependentHierarchyItemList())

    @buildHierarchyItems: ->
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: window.t('javascripts.collections.fields.no_value')})

    @initDependentHierarchyItemList: ->
      if @isDependentFieldHierarchy()
        if @parentHierarchyFieldId == ''
          return @hierarchy
        else
          parentField = window.model.editingSite()?.findFieldByEsCode(@parentHierarchyFieldId)
          if parentField
            return new FieldDependant(null, parentField).dependentHierarchyItemList(@fieldHierarchyItems())

      return []

    @updateDependentFieldsHierarchyItemList: ->
      site = window.model.newOrEditSite()
      if site && @isDependentFieldHierarchy()
        new FieldDependant(site, @).updateDependentFieldsHierarchyItemList()

    @isDependentFieldHierarchy: ->
      return @kind == 'hierarchy' && @is_enable_dependancy_hierarchy()

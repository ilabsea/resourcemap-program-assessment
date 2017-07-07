onLayers ->
  class @Field_hierarchy extends @FieldImpl
    constructor: (field) ->
      super(field)
      @hierarchy = ko.observable field.config?.hierarchy
      @uploadingHierarchy = ko.observable(false)
      @errorUploadingHierarchy = ko.observable(false)
      @parentHierarchyFieldId = ko.observable field.config?.parent_hierarchy_field_id ? ""

      @field.is_enable_dependancy_hierarchy.subscribe =>
        @parentHierarchyFieldId('') if @field.is_enable_dependancy_hierarchy() == false

      @initHierarchyItems() if @hierarchy()



      @error = ko.computed =>
        if @hierarchy() && @hierarchy().length > 0
          null
        else
          "the field #{@field.fieldErrorDescription()} is missing the Hierarchy"

    setHierarchy: (hierarchy) =>
      @hierarchy(hierarchy)
      @initHierarchyItems()
      @uploadingHierarchy(false)
      @errorUploadingHierarchy(false)

    initHierarchyItems: =>
      @hierarchyItems = ko.observableArray $.map(@hierarchy(), (x) -> new HierarchyItem(x))

    toJSON: (json) =>
      json.config =
                hierarchy: @hierarchy()
                parent_hierarchy_field_id: @parentHierarchyFieldId()
                field_logics: $.map(@field_logics(), (x) ->  x.toJSON())

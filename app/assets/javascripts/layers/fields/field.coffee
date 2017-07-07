onLayers ->
  class @Field

    constructor: (layer, data) ->
      @layer = ko.observable layer
      @id = ko.observable data?.id
      @name = ko.observable data?.name ? ''
      @code = ko.observable data?.code ? ''
      @kind = ko.observable data?.kind
      @threshold_ids = data?.threshold_ids ? []
      @query_ids = data?.query_ids ? []
      @report_query_ids = data?.report_query_ids ? []

      @editableCode = ko.observable(true)
      @deletable = ko.observable(true)

      @is_enable_field_logic = ko.observable data?.is_enable_field_logic ? false
      @is_enable_custom_validation = ko.observable data?.is_enable_custom_validation ? false
      @is_enable_field_custom_validation = ko.observable data?.is_enable_field_custom_validation ? false
      @is_enable_range = data?.is_enable_range
      @is_enable_dependancy_hierarchy = ko.observable data?.is_enable_dependancy_hierarchy ? false

      @config = data?.config
      @field_logics_attributes = data?.field_logics_attributes
      @metadata = data?.metadata
      @is_mandatory = data?.is_mandatory
      @is_display_field = data?.is_display_field
      @custom_widgeted = ko.observable data?.custom_widgeted ? false
      @readonly_custom_widgeted = data?.readonly_custom_widgeted

      @kind_titleize = ko.computed =>
        (@kind().split(/_/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      @ord = ko.observable data?.ord

      @hasFocus = ko.observable(false)
      @isNew = ko.computed =>  !@id()?

      @fieldErrorDescription = ko.computed => if @hasName() then "'#{@name()}'" else "number #{@layer().fields().indexOf(@) + 1}"

      # Tried doing "@impl = ko.computed" but updates were triggering too often
      @impl = ko.observable eval("new Field_#{@kind()}(this)")
      @kind.subscribe => @impl eval("new Field_#{@kind()}(this)")

      @widgetMappingerror = ko.observable()
      @nameError = ko.computed => if @hasName() then null else "the field #{@fieldErrorDescription()} is missing a Name"
      @codeError = ko.computed =>
        if !@validCode() then return "the field #{@fieldErrorDescription()} has invalid code"
        if !@hasCode() then return "the field #{@fieldErrorDescription()} is missing a Code"
        if (@code() in ['lat', 'long', 'name', 'resmap-id', 'last updated']) then return "the field #{@fieldErrorDescription()} code is reserved"
        null

      @error = ko.computed => @nameError() || @codeError() || @impl().error()
      @valid = ko.computed => !@error()
      @oldcode = ko.observable data?.code
      @code.subscribe =>
        unless @editableCode()
          @changeCodeInCalculationField()
      @custom_widgeted.subscribe =>
        if @custom_widgeted() == true
          @is_enable_field_logic(false)
          if(@config and @config.field_logics)
            @config.field_logics = []
          @impl().field_logics([])

    changeCodeInCalculationField: =>
      $.map(model.layers(), (x, index) =>
        fields = x.fields()
        new_fields = []
        $.map(fields, (f) =>
          if f.kind() == "calculation"
            search = "${" + @oldcode() + "}"
            replace = "${" + @code() + "}"
            re = new RegExp(search, 'g')
            f.impl().codeCalculation(@replaceAll(f.impl().codeCalculation(), search , replace))
            $.map(f.impl().dependent_fields(), (df, index) =>
              if df.id().toString() == @id().toString()
                f.impl().dependent_fields()[index].code(@code())
            )
          new_fields.push(f)
        )
        model.layers()[index].fields(new_fields)
      )
      @oldcode(@code())

    escapeRegExp: (string) =>
      return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");

    replaceAll: (string, find, replace) =>
      return string.replace(new RegExp(@escapeRegExp(find), 'g'), replace);

    hasName: => $.trim(@name()).length > 0

    hasCode: => $.trim(@code()).length > 0

    validCode: =>
      if @code()?.match(/[^A-Za-z0-9_]/) then return false else return true

    selectingLayerClick: =>
      @switchMoveToLayerElements true
      return

    selectingLayerSelect: =>
      return unless @selecting

      if window.model.currentLayer() != @layer()
        window.model.moveFieldCrossLayer(@, @layer())
        $("a[id='#{@name()}']").html("Move to layer '#{@layer().name()}' upon save")
      else
        $("a[id='#{@name()}']").html('Move to layer...')
      @switchMoveToLayerElements false

    switchMoveToLayerElements: (v) =>
      $("a##{@name()}").toggle()
      $("select[id='#{@name()}']").toggle()
      @selecting = v

    buttonClass: =>
      FIELD_TYPES[@kind()].css_class

    iconClass: =>
      FIELD_TYPES[@kind()].small_css_class

    isAllowMandatoryConfig: =>
      return (@kind() != 'custom_widget')

    isAllowDigitPrecisionConfig: =>
      return (@kind() in ['numeric', 'calculation'])

    isAllowFieldLogicConfig: =>
      return model?.selectLogicLayers().length > 0

    isAllowDependancyHierarchyFieldConfig: =>
      return (@is_enable_dependancy_hierarchy() && model?.layersWithHierarchyFields().length > 0)

    isSelectable: =>
      return (@kind() in ['select_one', 'select_many'])

    isWidgetable: =>
      return  (@kind() in ['numeric', 'select_one'])

    isRemovable: =>
      is_dependency_of_other = ( @isHavingRelationWithOther() || @isParentOfOther())
      if is_dependency_of_other then return false else return true

    isHavingRelationWithOther: => (@threshold_ids.length > 0 || @query_ids.length > 0 || @report_query_ids.length > 0)

    isParentOfOther: =>
      return false unless @id()
      for layer in model?.layers()
        is_parent_of_other = layer.fields().filter((f) => "#{f.impl()?.parentHierarchyFieldId?()}" == "#{@id()}").length > 0
        return true if is_parent_of_other
      return false

    isParentOfOtherLayerField: (layer) =>
      return false unless @id()
      layers = model?.layers().filter((l) => l != layer)
      for l in layers
        is_parent_of_other = l.fields().filter((f) => "#{f.impl()?.parentHierarchyFieldId?()}" == "#{@id()}").length > 0
        return true if is_parent_of_other
      return false

    toJSON: =>
      @code(@code()?.trim())
      json =
        id: @id()
        name: @name()
        code: @code()
        kind: @kind()
        ord: @ord()
        layer_id: @layer().id()
        is_mandatory: @is_mandatory
        is_display_field: @is_display_field
        is_enable_field_logic: @is_enable_field_logic()
        is_enable_custom_validation: @is_enable_custom_validation()
        is_enable_dependancy_hierarchy: @is_enable_dependancy_hierarchy()
        is_criteria: @is_criteria
        custom_widgeted: @custom_widgeted()
        readonly_custom_widgeted: @readonly_custom_widgeted
      @impl().toJSON(json)
      json

  class @FieldImpl
    constructor: (field) ->
      @field = field
      @maximumSearchLengthError = ko.observable()
      @error = ko.observable()
      @field_logics = if field.config?.field_logics?
                        ko.observableArray(
                          $.map(field.config.field_logics, (x) -> new FieldLogic(x))
                        )
                      else
                        ko.observableArray()

    saveFieldLogic: (field_logic) =>
      if !field_logic.id()?
        if @field_logics().length > 0
          id = @field_logics()[@field_logics().length - 1].id() + 1
        else
          id = 0
        field_logic.id id
        @field_logics.push field_logic

    toJSON: (json) =>
      unless json.config
        json.config = {}
      json.config["field_logics"] = $.map(@field_logics(), (x) ->  x.toJSON())

  class @Field_date extends @FieldImpl

  class @Field_site extends @FieldImpl

  class @Field_user extends @FieldImpl

  class @Field_photo extends @FieldImpl

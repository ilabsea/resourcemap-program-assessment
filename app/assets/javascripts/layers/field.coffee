onLayers ->
  class @Field
    constructor: (layer, data) ->
      @layer = ko.observable layer
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @code = ko.observable data?.code
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
      @is_criteria = data?.is_criteria
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
      if @kind() == 'location'
        return 'llocation'
      FIELD_TYPES[@kind()].css_class

    iconClass: =>
      if @kind() == 'location'
        return 'slocation'
      FIELD_TYPES[@kind()].small_css_class

    toJSON: =>
      @code(@code().trim())
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
        is_criteria: @is_criteria
        custom_widgeted: @custom_widgeted()
        readonly_custom_widgeted: @readonly_custom_widgeted
      @impl().toJSON(json)
      json

  class @FieldImpl
    constructor: (field) ->
      @field = field
      @maximumSearchLengthError = -> null
      @error = -> null
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

  class @Field_text extends @FieldImpl
    constructor: (field) ->
      super(field)
      @attributes = if field.metadata?
                      ko.observableArray($.map(field.metadata, (x) -> new Attribute(x)))
                    else
                      ko.observableArray()
      @advancedExpanded = ko.observable false

    toggleAdvancedExpanded: =>
      @advancedExpanded(not @advancedExpanded())

    addAttribute: (attribute) =>
      @attributes.push attribute

    toJSON: (json) =>
      json.metadata = $.map(@attributes(), (x) -> x.toJSON())
      json.config = { field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

  class @Field_numeric extends @FieldImpl
    constructor: (field) ->
      super(field)

      @allowsDecimals = ko.observable field?.config?.allows_decimals == 'true'
      @digitsPrecision = ko.observable field?.config?.digits_precision
      @is_enable_range = ko.observable field?.is_enable_range ? false
      @minimum = ko.observable field?.config?.range?.minimum
      @maximum = ko.observable field?.config?.range?.maximum
      @error = ko.computed =>
        if (@is_enable_range() && @minimum() && @minimum())&& parseInt(@minimum()) > parseInt(@maximum())
          "Invalid range, maximum must greater than minimum"

      @field_validations = if field.config?.field_validations?
                        ko.observableArray(
                          $.map(field.config.field_validations, (x) -> new FieldValidation(x))
                        )
                      else
                        ko.observableArray([])

    validate_number_only: (field,event) =>
      if event.keyCode > 31 && (event.keyCode < 48 || event.keyCode > 57)
        return false
      return true

    toJSON: (json) =>
      json.is_enable_range = @is_enable_range()
      json.config = { digits_precision: @digitsPrecision(), allows_decimals: @allowsDecimals(), range: {minimum: @minimum(), maximum: @maximum()}, field_logics: $.map(@field_logics(), (x) ->  x.toJSON()), field_validations: $.map(@field_validations(), (x) ->  x.toJSON())}
      return json


    saveFieldValidation: (field_validation) =>
      if !field_validation.id()?
        if @field_validations().length > 0
          id = @field_validations()[@field_validations().length - 1].id() + 1
        else
          id = 0
        field_validation.id id
        @field_validations.push field_validation

  class @Field_yes_no extends @FieldImpl
    constructor: (field) ->
      super(field)

      @field_logics = if field.config?.field_logics?
                        ko.observableArray(
                          $.map(field.config.field_logics, (x) -> new FieldLogic(x))
                        )
                      else
                        ko.observableArray()

    validFieldLogic: =>
      @field_logics().filter (field_logic) -> typeof field_logic.field_id() isnt 'undefined'

    toJSON: (json) =>
      json.config = {field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

  class @FieldSelect extends @FieldImpl
    constructor: (field) ->
      super(field)
      @options = if field.config?.options?
                   ko.observableArray($.map(field.config.options, (x) -> new Option(x)))
                 else
                   ko.observableArray()
      @nextId = field.config?.next_id || @options().length + 1
      @error = ko.computed =>
        if @options().length > 0
          codes = []
          labels = []
          for option in @options()
            return "duplicated option code '#{option.code()}' for field #{@field.name()}" if codes.indexOf(option.code()) >= 0
            return "duplicated option label '#{option.label()}' for field #{@field.name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          "the field '#{@field.name()}' must have at least one option"


    addOption: (option) =>
      option.id @nextId
      @options.push option
      @nextId += 1

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId}

  class @Field_select_one extends @FieldSelect
    constructor: (field) ->
      super(field)

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId,field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

  class @Field_select_many extends @FieldSelect
    constructor: (field) ->
      super(field)
      @selected_field_logics = if field.config?.field_logics?
        ko.observableArray(
          $.map(field.config.field_logics, (x) -> new FieldLogic(x))
        )
      else
        ko.observableArray()

    add_field_logic: (field_logic) =>
      @field_logics.push field_logic

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId,field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}


  class @Field_hierarchy extends @FieldImpl
    constructor: (field) ->
      super(field)
      @hierarchy = ko.observable field.config?.hierarchy
      @uploadingHierarchy = ko.observable(false)
      @errorUploadingHierarchy = ko.observable(false)
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
      json.config = {hierarchy: @hierarchy(),field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}


  class @Field_date extends @FieldImpl

  class @Field_site extends @FieldImpl

  class @Field_user extends @FieldImpl

  class @Field_photo extends @FieldImpl

  class @Field_location extends @FieldImpl
    constructor: (field) ->
      super(field)
      @maximumSearchLength = ko.observable(field?.config?.maximumSearchLength)
      @uploadingLocation = ko.observable(false)
      @errorUploadingLocation = ko.observable(false)
      @locations = if field?.config?.locations
                    ko.observableArray($.map(field?.config?.locations, (x) -> new Location(x)))
                   else
                    ko.observableArray()

      @maximumSearchLengthError = ko.computed =>
        if @maximumSearchLength() && @maximumSearchLength().length >0
          null
        else
          "the field #{@field.fieldErrorDescription()} is missing a maximum search length"
      @missingFileLocationError = ko.computed =>
        if @locations() && @locations().length > 0
          null
        else
          "the field #{@field.fieldErrorDescription()} is missing the location file"

      @error = ko.computed =>
        @missingFileLocationError() || @maximumSearchLengthError()

    setLocation: (locations) =>
      @locations($.map(locations, (x) -> new Location(x)))
      @uploadingLocation(false)
      @errorUploadingLocation(false)

    toJSON: (json)=>
      json.config = {locations: $.map(@locations(), (x) ->  x.toJSON()), maximumSearchLength: @maximumSearchLength(),field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

  class @Field_calculation extends @FieldImpl
    constructor: (field) ->
      super(field)
      @allowsDecimals = ko.observable field?.config?.allows_decimals == 'true'
      @digitsPrecision = ko.observable field?.config?.digits_precision
      @dependent_fields = if field.config?.dependent_fields?
                            ko.observableArray(
                              $.map(field.config.dependent_fields, (x) -> new FieldDependant(x))
                            )
                          else
                            ko.observableArray()
      @field = ko.observable()
      @codeCalculation = ko.observable field.config?.code_calculation ? ""
    addDependentField: (field) =>
      fields = @dependent_fields().filter (f) -> f.id() is field.id()
      if fields.length == 0
        field.editableCode(false)
        @dependent_fields.push(new FieldDependant(field.toJSON()))

    removeDependentField: (field) =>
      @dependent_fields.remove field

    addFieldToCodeCalculation: (field) =>
      @codeCalculation(@codeCalculation() + '${' + field.code() + "}")
    toJSON: (json) =>
      json.config = {digits_precision: @digitsPrecision(), allows_decimals: @allowsDecimals(), code_calculation: @codeCalculation(), dependent_fields: $.map(@dependent_fields(), (x) ->  x.toJSON())}

  class @Field_custom_widget extends @FieldImpl
    constructor: (field) ->
      super(field)
      @widgetContent = ko.observable field?.config?.widget_content
    toJSON: (json) =>
      json.config = { widget_content: @widgetContent(),field_logics: $.map(@field_logics(), (x) ->  x.toJSON())}

  class @Field_custom_aggregator extends @FieldImpl
    constructor: (field) ->
      super(field)
      @_fieldList = ko.observableArray([])
      @conditionFieldId = ko.observable(field.config?.condition_field_id)

      @selectedCollectionFieldList = ko.observableArray([])
      @selectedCollection = ko.observable(field.config?.selected_collection)

      @selectedCollection.subscribe =>
        @findFieldByCollectionId(@selectedCollection())

      @aggregatorTypeList = ['SUM']
      @selectedAggregatorType = ko.observable(field.config?.selected_aggregator_type)
      @selectedCustomWidgetFieldList = ko.computed =>
        @selectedCollectionFieldList().filter ((field) -> field.custom_widgeted())

      @selectedCustomWidgetField = ko.observable()
      # data get stored in hash format, not in array's
      @aggregatedFieldList = ko.observableArray($.map(field.config?.aggregated_field_list || [] , (x) =>  {id: x.id, code: x.code, name: x.name}))
      @conditionFieldValue = ko.observable(field.config?.condition_field_value)

      @error = ko.computed =>
        return "the field must reference to a collection " unless @selectedCollection()
        return "the field must have the aggregator type" unless @selectedAggregatorType()
        return "the field must have the aggregator field list" if @aggregatedFieldList().length == 0

    findFieldByCollectionId: (collectionId) =>
      return @selectedCollectionFieldList([]) if !collectionId || @layer().id() == undefined

      layer_id = @layer().id()
      $.get "/collections/#{collectionId}/basic_fields.json?layer_id=#{layer_id}", {}, (fields) =>
        fields.sort((x, y) -> if x.name.toLowerCase().trim() < y.name.toLowerCase().trim() then -1 else 1)
        @selectedCollectionFieldList(fields)
        #Initially selectedCollectionFieldList is empty then conditionFieldId will be forced to undefined
        @conditionFieldId(@field.config?.condition_field_id)

    addCustomWidgetedFieldItem: =>
      if @selectedCustomWidgetField()
        found = false
        for aggregatedField in @aggregatedFieldList()
          if @selectedCustomWidgetField().code == aggregatedField.code
            found = true
            break
        @aggregatedFieldList.push @selectedCustomWidgetField() if found == false

    removeCustomWidgetedFieldItem: (item) =>
      @aggregatedFieldList.remove(item)

    model: =>
      window.test = @field.layer().parent()

    findFieldById: (id) =>
      result = @fieldList().filter (field) -> field.id == parseInt(id)
      result[0]

    findCollectionById: (id) =>
      result = @collectionList().filter (collection) ->
        collection.id == parseInt(id)
      result[0]


    # cannot get it from window.model since this variable does not exist yet
    # we are forming the new MainViewModel constructor
    collectionList: =>
      window.collectionList

    layerList: =>
      window.layerList

    fieldList: =>
      return @_fieldList() if @_fieldList().length > 0
      fields = []
      for layer in @layerList()
        fields = fields.concat(layer.fields)
      fields.sort (first, second)->
        firstItem = first.name.toLowerCase()
        secondItem = second.name.toLowerCase()
        if firstItem < secondItem
          return -1
        else if firstItem == secondItem
          return 0
        else
          return 1
      @_fieldList(fields)
      return @_fieldList()

    toJSON: (json) =>
      json.is_custom_aggregator = true
      json.config = {
        selected_collection: @selectedCollection(),
        selected_aggregator_type: @selectedAggregatorType(),
        aggregated_field_list: $.map(@aggregatedFieldList(), (x) =>  {id: x.id, code: x.code, name: x.name}),
        condition_field_id: @conditionFieldId(),
        condition_field_value: @conditionFieldValue()

      }

  class @Field_email extends @Field_text

  class @Field_phone extends @Field_text

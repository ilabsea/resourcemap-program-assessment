onLayers ->
  class @Layer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @public = ko.observable data?.public
      @ord = ko.observable data?.ord
      @threshold_ids = data?.threshold_ids ? []
      @query_ids = data?.query_ids ? []
      @report_query_ids = data?.report_query_ids ? []
      @fields = if data?.fields
                  ko.observableArray($.map(data.fields, (x) => new Field(@, x)))
                else
                  ko.observableArray([])

      @hierarchyFields = ko.computed =>
                            if model?.currentField()
                              @fields().filter (f) => f.kind() == 'hierarchy' && f != model.currentField()
                            else
                              @fields().filter (f) => f.kind() == 'hierarchy'

      @numeric_fields = ko.observableArray($.map(@fields(), (f) => f if f.kind() == 'numeric'))
      @support_skiplogic_fields = ko.observableArray($.map(@fields(), (f) => f if (f.kind() == 'numeric' or f.kind() == 'yes_no' or f.kind() == 'select_one' or f.kind() == 'select_many')))
      @deletable = ko.observable(true)
      @hasFocus = ko.observable(false)
      @nameError = ko.computed => if @hasName() then null else "the layer's Name is missing"
      @total = ko.observable(data?.total ? 0)
      @lastFieldOrd = data?.last_field_ord ? 0
      @fieldsError = ko.computed =>
        return "the layer must have at least one field" if @fields().length == 0

        codes = []
        names = []

        # Check that the name and code are not duplicated
        for field in @fields()
          field_error = field.error()
          return field_error if field_error
          return "duplicated field name '#{field.name()}'" if names.indexOf(field.name()) >= 0
          return "duplicated field code '#{field.code()}'" if codes.indexOf(field.code()) >= 0
          names.push field.name()
          codes.push field.code()

        # Now check that the names and codes don't apper in other layers
        if window.model
          for layer in window.model.layers() when layer != @
            for field in layer.fields()
              return "a field with name '#{field.name()}' already exists in the layer named #{layer.name()}" if names.indexOf(field.name()) >= 0
              return "a field with code '#{field.code()}' already exists in the layer named #{layer.name()}"  if codes.indexOf(field.code()) >= 0

        null
      @error = ko.computed => @nameError() || @fieldsError()
      @valid = ko.computed => !@error()

    hasName: => $.trim(@name()).length > 0

    expandAllField: (layer)=>
      $.get "/collections/#{collectionId}/layers/#{layer.id()}.json", {}, (l) =>
        f = ko.observableArray($.map(l["fields"], (x) => new Field(@, x)))
        layer.fields(f())
        layer.total(null)

    modifyDependentFieldCustomWidget: (replace_fields) =>
      $.map(@fields(), (field) =>
        if field.kind() == "custom_widget"
          $.map(replace_fields, (item) =>
            field.config.widget_content = @replaceAll(field.config.widget_content, "{" + item["old_field"] + "}", "{" + item["new_field"] + "}")
            field.impl().widgetContent(field.config.widget_content)

          )
      )

    replaceAll: (string, find, replace) =>
      return string.replace(new RegExp(@escapeRegExp(find), 'g'), replace);

    escapeRegExp: (string) =>
      return string.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1");

    toJSON: =>
      id: @id()
      name: @name()
      ord: @ord()
      public: @public()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())

    widgetFields: =>
      @fields().filter ((field) -> field.kind() == "custom_widget")

    isRemovable: =>
      isDependencyOfOtherLayer = (@threshold_ids.length > 0 || @query_ids.length > 0 || @report_query_ids.length > 0 || @isHavingRelationWithOther() || @isParentFieldOfOtherLayerField())
      if isDependencyOfOtherLayer then return false else return true

    isHavingRelationWithOther: =>
      for field in @fields()
        return true if field.isHavingRelationWithOther()
      return false

    isParentFieldOfOtherLayerField: =>
      return false if model?.layers().length == 1
      layers = model?.layers().filter((l) => l != @)
      for field in @fields()
        for layer in layers
          isParentOfOther = layer.fields().filter((f) => "#{f.impl()?.parent_hiearchy_id?()}" == "#{field.id()}").length > 0
          return true if isParentOfOther
      return false

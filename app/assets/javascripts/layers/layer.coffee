onLayers ->
  class @Layer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @public = ko.observable data?.public
      @ord = ko.observable data?.ord
      @threshold_ids = data?.threshold_ids ? []
      @query_ids = data?.query_ids ? []
      @total = ko.observable data?.total ? 0
      if data?.fields
        @fields = ko.observableArray($.map(data.fields, (x) => new Field(@, x)))
        @numeric_fields = ko.observableArray($.map(@fields(), (f) => f if f.kind() == 'numeric'))
      else
        @fields = ko.observableArray([])
      @deletable = ko.observable(true)
      @hasFocus = ko.observable(false)
      @nameError = ko.computed => if @hasName() then null else "the layer's Name is missing"
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
        f = ko.observableArray($.map(l["fields"], (x) => new Field(self, x)))
        layer.fields(f())
        layer.total(null)

    toJSON: =>
      id: @id()
      name: @name()
      ord: @ord()
      public: @public()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())

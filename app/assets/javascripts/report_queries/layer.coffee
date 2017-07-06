onReportQueries ->
  class @Layer
    constructor: (data) ->
      @id = data?.id
      @name = data?.name
      @public = data?.public
      @ord = data?.ord
      @fields = if data?.fields
                  $.map(data.fields, (x) => new Field(@, x))
                else
                  []
      @fieldsNumericOnly = @fields.filter (field) -> field.kind == 'numeric'

      @expanded = ko.observable(false)
      @whiteListFieldType = ['text', 'numeric', 'yes_no', 'select_one', 'hierarchy', 'date', 'calculation', 'location', 'email', 'phone']
      @whiteListConditionField = @fields.filter (field) => @whiteListFieldType.includes?(field.kind)

    toggleExpand: =>
      @expanded(!@expanded())

    toJSON: =>
      id: @id()
      name: @name()
      ord: @ord()
      public: @public()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())

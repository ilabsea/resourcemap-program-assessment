onQueries ->
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

    toJSON: =>
      id: @id()
      name: @name()
      ord: @ord()
      public: @public()
      fields_attributes: $.map(@fields(), (x) -> x.toJSON())

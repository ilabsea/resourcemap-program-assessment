onCollections ->
  class @Layer
    constructor: (data) ->
      @id = data?.id
      @name = data?.name
      @fields = $.map data.fields, (x) => new Field(x, @id)
      @expanded = ko.observable(false)
      @error = ko.observable(false)

    toggleExpand: =>
      @expanded(!@expanded())
      if @expanded()
        $.map @fields, (f) =>
          f.init()
          f.refresh_skip()
          f.bindWithCustomWidgetedField()

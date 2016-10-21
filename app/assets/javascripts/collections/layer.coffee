onCollections ->
  class @Layer
    constructor: (data) ->
      @name = data?.name
      @fields = $.map data.fields, (x) => new Field x
      @expanded = ko.observable(false)

    toggleExpand: =>
      @expanded(!@expanded())
      if @expanded()
        $.map @fields, (f) =>
          f.refresh_skip()
          f.bindWithCustomWidgetedField()

onCollections ->
  class @Layer
    constructor: (data) ->
      @id = data?.id
      @name = data?.name
      @fields = $.map data.fields, (x) => new Field(x, @id)
      @expanded = ko.observable(false)
      @error = ko.computed =>
        fieldError = @fields.filter((f) => f.error() == true )
        if fieldError.length > 0 then 'error' else ''

    toggleExpand: =>
      @expanded(!@expanded())
      if @expanded()
        $.map @fields, (f) =>
          f.init()
          f.refresh_skip()
          f.bindWithCustomWidgetedField()
        window.model.newOrEditSite()?.prepareCalculatedField()

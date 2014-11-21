onLayers ->
  class @FieldDependant
  	constructor: (data) ->
      @id = ko.observable(data?.id)
      @name = ko.observable(data?.name)
      @code = ko.observable(data?.code)
      @kind = ko.observable(data?.kind)
    toJSON: =>
      id: @id()
      name: @name()
      code: @code()
      kind: @kind()

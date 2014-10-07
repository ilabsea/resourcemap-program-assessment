onQueries ->
  class @Field
    constructor: (layer, data) ->
      @layer = layer
      @id = data?.id
      @name = data?.name
      @code = data?.code
      @kind = data?.kind
      @config = data?.config
      @metadata = data?.metadata
      @is_mandatory = data?.is_mandatory

      @kind_titleize = ko.computed =>
        (@kind.split(/_/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      @ord = data?.ord

    toJSON: =>
      @code = @code.trim()
      json =
        id: @id
        name: @name
        code: @code
        kind: @kind
        ord: @ord
        layer_id: @layer.id
        is_mandatory: @is_mandatory      
      json

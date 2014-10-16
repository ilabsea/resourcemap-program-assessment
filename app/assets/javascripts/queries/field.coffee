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
      @value = ko.observable(data?.value)
      @kind_titleize = ko.computed =>
        (@kind.split(/_/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      @ord = data?.ord
      if @kind == 'hierarchy'
        @hierarchy = data.config?.hierarchy

      @buildHierarchyItems() if @hierarchy?
      @valueUI =  ko.computed
       read: =>  @valueUIFor(@value())
       write: (value) =>
         @value(@valueUIFrom(value))

    buildHierarchyItems: =>
      @fieldHierarchyItemsMap = {}
      @fieldHierarchyItems = ko.observableArray $.map(@hierarchy, (x) => new FieldHierarchyItem(@, x))
      @fieldHierarchyItems.unshift new FieldHierarchyItem(@, {id: '', name: '(no value)'})
    valueUIFor: (value) =>
      if @kind == 'yes_no'
        if value then 'yes' else 'no'
      else if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else
        if value then value else ''

    valueUIFrom: (value) =>
      if @kind == 'site'
        # Return site_id or "" if the id for this name is not found (deleting the value or invalid value)
        window.model.currentCollection()?.findSiteIdByName(value) || ""
      else
        value
        
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

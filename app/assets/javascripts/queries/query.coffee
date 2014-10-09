onQueries ->
  class @Query
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name

      @conditions = if data?.conditions
                      ko.observableArray $.map(data.conditions, (x) => new Condition(x))
                    else
                      ko.observableArray()

      @nameError = ko.computed => if @hasName()  then null else "the query's name is missing"
      @queryError = ko.computed => if @conditions().length > 0  then null else "the query must have at least one condition refined"
      @error = ko.computed => @nameError() || @queryError()
      @valid = ko.computed => !@error()
      @isEditing = ko.observable(false)
      @isRefineQuery = ko.observable(false)


    hasName: => $.trim(@name()).length > 0

    addCondition: =>
      @conditions.push(new Condition)

    removeCondition: (condition) =>
      @conditions.remove(condition)

    toJSON: =>
      id: @id()
      name: @name()
      conditions: $.map(@conditions(), (x) -> x.toJSON())
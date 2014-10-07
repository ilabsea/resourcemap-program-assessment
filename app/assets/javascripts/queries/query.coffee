onQueries ->
  class @Query
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name

      @conditions = if data?.conditions
                      ko.observableArray $.map(data.conditions, (x) => new Condition(x))
                    else
                      ko.observableArray([new Condition])
      @isAllSite = ko.observable data?.is_all_site.toString() ? "true"
      @isAllCondition = ko.observable data?.is_all_condition.toString() ? "true"
      @nameError = ko.computed => if @hasName() then null else "the query's Name is missing"
      @error = ko.computed => @nameError()
      @valid = ko.computed => !@error()
      @isEditing = ko.observable(false)
    hasName: => $.trim(@name()).length > 0

    addCondition: =>
      # @newCondition(new Condition)
      @conditions.push(new Condition)

    removeCondition: (condition) =>
      @conditions.remove(condition)

    toJSON: =>
      id: @id()
      name: @name()
      is_all_site: @isAllSite()
      is_all_condition: @isAllCondition()
      conditions: $.map(@conditions(), (x) -> x.toJSON())
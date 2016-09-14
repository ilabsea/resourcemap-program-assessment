onReportQueries ->
  class @ReportQuery
    constructor: (data) ->
      @id = data?.id
      @name = ko.observable data?.name
      @condition = ko.observable data?.condition ? ""
      @conditionFields = if data?.condition_fields
                           ko.observableArray $.map(data.condition_fields, (x) => new Condition(x))
                         else
                           ko.observableArray([])

      @groupByFieldsOptions = ko.observable()
      @selectedGroupByField = ko.observable(@groupByFieldsOptions()?[0])
      @groupByFields = if data?.group_by_fields
                          ko.observableArray $.map(data.group_by_fields, (x) => window.model.findFieldById(x))
                       else
                          ko.observableArray([])

      @aggregateFields = if data?.aggregate_fields
                           ko.observableArray $.map(data.aggregate_fields, (x) => new Aggregate(x))
                         else
                           ko.observableArray([])

      @isEditing = ko.observable()

      @nameError = ko.computed => if @hasName()  then null else "the query's name is missing"
      @groupByFieldError = ko.computed => @hasGroupByFields()
      @aggregateFieldError = ko.computed => if @hasAggregateFields()  then null else "the query must have at least one aggregate"
      @error = ko.computed => @nameError() || @nameExist() || @aggregateFieldError()
      @valid = ko.computed => !@error()

    nameExist: =>
      for reportQuery in window.model.reportQueries()
        if reportQuery.id != window.model.currentReportQuery()?.id && @name().trim() == reportQuery.name().trim()
          return "the query'name is already exist"

    hasName: => $.trim(@name()).length > 0
    hasCondition: => $.trim(@condition()).length > 0
    hasConditionFields: => @conditionFields().length > 0
    hasGroupByFields: => @selectedGroupByField() != ""
    hasAggregateFields: => @aggregateFields().length > 0


    LogicalOperatorError: => if @isLogicalOperatorExpr().status then null else "the formula #{@isLogicalOperatorExpr().msg}"

    addConditionField: (condition) =>
      condition.id = @conditionId()
      @conditionFields.push(condition)
      window.model.newCondition(new Condition())

    conditionId: =>
      if @conditionFields().length > 0
        numCondition = @conditionFields().length
        lastCondition = @conditionFields()[numCondition - 1]
        return parseInt(lastCondition.id) + 1
      else
        return 1

    removeConditionField: (condition) =>
      @conditionFields.remove(condition)

    addGroupByField: =>
      @groupByFields.push(@selectedGroupByField())

    removeGroupByField: (field) =>
      @groupByFields.remove(field)

    addAggregatField: (aggregate) =>
      aggregate.id = @aggregateId()
      @aggregateFields.push(aggregate)
      window.model.newAggregate(new Aggregate())

    aggregateId: =>
      if @aggregateFields().length > 0
        numAggregate = @aggregateFields().length
        lastAggregate = @aggregateFields()[numAggregate - 1]
        return parseInt(lastAggregate.id) + 1
      else
        return 1

    removeAggregateField: (field) =>
      @aggregateFields.remove(field)

    toJSON: =>
      id: @id
      name: @name().trim()
      condition_fields: $.map(@conditionFields(), (x) -> x.toJSON())
      group_by_fields: $.map(@groupByFields(), (x) -> "#{x.id}")
      aggregate_fields: $.map(@aggregateFields(), (x) -> x.toJSON())
      condition: @condition()

    tokenize: =>
      results = []
      tokenRegExp = /\s*([A-Za-z]+|[0-9]+|\S)\s*/g
      formula = @formula()
      formula = formula.toLowerCase()
      m = undefined
      while (m = tokenRegExp.exec(formula)) != null
        results.push m[1]

      results

    condition_ids: =>
      ids = []
      for condition in @conditions()
        ids.push(parseInt(condition.id()))
      ids

    isLogicalOperatorExpr: =>
      tokens = @tokenize(@formula())
      position = 0
      ids = @condition_ids()

      peek = ->
        tokens[position]

      isValidNumber = (t)->
        if t != undefined && t.match(/^[0-9]+$/) != null
          ids.indexOf(parseInt(t)) > -1

      isPrimaryExpr = ->
        t = peek()
        if isValidNumber(t)
          position++
          return {status: true, msg: "number"}
        else if t == '('
          position++
          expr = isExpr()
          if peek() != ')'
            expr = {status: false, msg: "expected )"}
          else
            position++
          return expr
        else
          return {status: false, msg:"expected a number, or parentheses"}

      isExpr = ->
        expr = isPrimaryExpr()
        t = peek()
        while t == "and" || t == "or"
          position++
          nextExpr = isPrimaryExpr()
          if !expr.status || !nextExpr.status
            expr = {status : false, msg: "expected number before or after \'"+ t + "\'"}
            break
          expr = {status: true, msg: ""}
          t = peek()
        expr

      result = isExpr()

      if position != tokens.length
        result = {status: false, msg: "has unexpected \'" + peek() + "\'"}

      result

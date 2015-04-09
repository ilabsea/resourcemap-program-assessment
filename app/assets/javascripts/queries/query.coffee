onQueries ->
  class @Query
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @formula = ko.observable data?.formula

      @conditions = if data?.conditions
                      ko.observableArray $.map(data.conditions, (x) => new Condition(x))
                    else
                      ko.observableArray()

      @nameError = ko.computed => if @hasName()  then null else "the query's name is missing"
      @queryError = ko.computed => if @conditions().length > 0  then null else "the query must have at least one condition refined"
      @formalaError = ko.computed => if @hasFormula() then null else "the formula is missing"
      @error = ko.computed => @nameError() || @queryError() || @formalaError()
      @valid = ko.computed => !@error()
      @isEditing = ko.observable(false)
      @isRefineQuery = ko.observable(false)

    hasName: => $.trim(@name()).length > 0

    hasFormula: => $.trim(@formula()).length > 0

    addCondition: =>
      @conditions.push(new Condition)

    removeCondition: (condition) =>
      @conditions.remove(condition)

    toJSON: =>
      id: @id()
      name: @name()
      formula: @formula()
      conditions: $.map(@conditions(), (x) -> x.toJSON())

    tokenize: =>
      results = []
      tokenRegExp = /\s*([A-Za-z]+|[0-9]+|\S)\s*/g
      m = undefined
      while (m = tokenRegExp.exec(@formula())) != null
        results.push m[1]
      console.log("results : ", results)
      results

    parse: =>
      tokens = @tokenize(@formula())
      position = 0

      peek = ->
        tokens[position]

      parsePrimaryExpr = ->
        t = peek()
        if t != undefined && t.match(/^[0-9]+$/) != null #isNumber
          position++
          return {status: true, msg: "number"}
        else if t == '('
          position++
          expr = parseExpr()
          if peek() != ')'
            expr = {status: false, msg: "expected )"}
          else 
            position++
          return expr
        else
          return {status: false, msg:"expected a number, or parentheses"}

      parseExpr = ->
        expr = parsePrimaryExpr()
        t = peek()
        while t == "AND" or t == "OR"
          position++
          nextExpr = parsePrimaryExpr()
          if !expr.status || !nextExpr.status
            expr = {status : false, msg: "Expected number before or after \'"+ t + "\'"}
            break
          expr = {status: true, msg: ""}
          t = peek()
        expr

      result = parseExpr()

      if position != tokens.length
        result = {status: false, msg: "unexpected \'" + peek() + "\'"}

      console.log "result : ", result
      result


















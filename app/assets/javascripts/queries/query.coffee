onQueries ->
  class @Query
    constructor: (data) ->
      console.log 'data : ', data
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @formula = ko.observable data?.formula

      @parse = data?.parse

      @conditions = if data?.conditions
                      ko.observableArray $.map(data.conditions, (x) => new Condition(x))
                    else
                      ko.observableArray()

      @nameError = ko.computed => if @hasName()  then null else "the query's name is missing"
      @queryError = ko.computed => if @conditions().length > 0  then null else "the query must have at least one condition refined"
      @formalaError = ko.computed => @hasFormulaError() || @LogicalOperatorError()
      @error = ko.computed => @nameError() || @queryError() || @formalaError()
      @valid = ko.computed => !@error()
      @isEditing = ko.observable(false)
      @isRefineQuery = ko.observable(false)

    hasName: => $.trim(@name()).length > 0

    hasFormula: => $.trim(@formula()).length > 0

    hasFormulaError: => if @hasFormula() then null else "the formula is missing"

    LogicalOperatorError: => if @parseLogicalOperatorExpr().status then null else "the formula #{@parseLogicalOperatorExpr().msg}"
    
    addCondition: =>
      @conditions.push(new Condition)

    removeCondition: (condition) =>
      @conditions.remove(condition)

    toJSON: ()=>
      id: @id()
      name: @name()
      formula: @formula()
      parse: @parseLogicalOperatorExpr()
      conditions: $.map(@conditions(), (x) -> x.toJSON())
    
    tokenize: =>
      results = []
      tokenRegExp = /\s*([A-Za-z]+|[0-9]+|\S)\s*/g
      m = undefined
      while (m = tokenRegExp.exec(@formula())) != null
        results.push m[1]
      results

    condition_ids: =>
      ids = []
      for condition in @conditions()
        ids.push(parseInt(condition.id()))
      ids

    parseLogicalOperatorExpr: =>
      tokens = @tokenize(@formula())
      position = 0
      ids = @condition_ids()

      peek = ->
        tokens[position]

      isValidNumber = (t)->
        if t != undefined && t.match(/^[0-9]+$/) != null
          ids.indexOf(parseInt(t)) > -1 

      parsePrimaryExpr = ->
        t = peek()
        if isValidNumber(t)
          position++
          return new Parse({status: true, msg: "number", condition_id: t})
        else if t == '('
          position++
          expr = parseExpr()
          if peek() != ')'
            expr = new Parse({status: false, msg: "expected )"})
          else 
            position++
          return expr
        else
          return new Parse({status: false, msg:"expected a number, or parentheses"})

      parseExpr = ->
        expr = parsePrimaryExpr()
        t = peek()
        if t != undefined && t.match(/^[A-Za-z]+$/) != null
          t = t.toUpperCase()
        while t == "AND" || t == "OR"
          position++
          nextExpr = parsePrimaryExpr()
          if !expr.status || !nextExpr.status
            expr = new Parse({status : false, msg: "expected number before or after \'"+ t + "\'"})
            break
          expr = new Parse({status: true, msg: "", logical_op: t, left: expr, right: nextExpr})
          t = peek()
        expr

      result = parseExpr()

      if position != tokens.length
        result = new Parse({status: false, msg: "has unexpected \'" + peek() + "\'"})

      console.log 'result : ', result

      result


















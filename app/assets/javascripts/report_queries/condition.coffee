onReportQueries ->
  class @Condition
    constructor: (data) ->
      @id = data?.id
      @operator = if data?.operator
                    ko.observable(@findOperatorByValue(data?.operator))
                  else
                    ko.observable(data?.operator)

      @selectedField = if data?.field_id
                        ko.observableArray([window.model.findFieldById(data.field_id)])
                       else
                         ko.observableArray()

      @field = ko.observable(@selectedField()?[0])

      @operatorOptions = ko.computed =>
        return @operatorUIForTextField() if @field()?.kind == 'text'
        return @operatorUIForNumericField() if @field()?.kind == 'numeric'

      @value = ko.observable(data?.value)

      @valueError = ko.computed => if @hasValue()  then null else "the condition field's value is missing"
      @error = ko.computed => @valueError()
      @valid = ko.computed => !@error()

    hasValue: => $.trim(@value()).length > 0
    # setField:
    operatorUIForTextField: =>
      [{label: "equal", value: "="}]
    operatorUIForNumericField: =>
      [{label: "equal", value: "="},
       {label: "greater than", value: ">"},
       {label: "less than", value: "<"}]

    findOperatorByValue: (value)=>
      allOperators = [{label: "equal", value: "="},{label: "greater than", value: ">"},{label: "less than", value: "<"}]
      allOperators.filter((x) -> x.value == value)[0]

    toJSON: =>
      id: @id
      field_id: @field().id
      operator: @operator().value
      value: @value()

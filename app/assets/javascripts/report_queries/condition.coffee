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
                         ko.observableArray([])

      @field = ko.observable(@selectedField()?[0])

      @operatorOptions = ko.computed =>
        singleFieldType = ['text', 'yes_no', 'select_one', 'hierarchy', 'location', 'date', 'email', 'phone']
        numeicFieldType = ['numeric', 'calculation']
        return @operatorUIForTextField() if singleFieldType.includes? @field()?.kind
        return @operatorUIForNumericField() if numeicFieldType.includes? @field()?.kind

      @value = ko.observable(data?.value)

      @valueUI =  ko.computed
       read: =>  @valueUIFor(@value())
       write: (value) =>
         @value(@valueUIFrom(value))

      @selectedField.subscribe =>
        @value('')

      @valueError = ko.computed => if @hasValue()  then null else "the condition field's value is missing"
      @fieldError = ko.computed => if @hasField() then null else "the condition field must selected"
      @operatorError = ko.computed => if @hasOperator() then null else "the operator must selected"

      @error = ko.computed => @fieldError() || @operatorError() || @valueError()
      @valid = ko.computed => !@error()

    hasField: => @field()?
    hasOperator: => @operator()?

    hasValue: => $.trim(@value()).length > 0

    valueUIFor: (value) =>
      if @field()?.kind == 'yes_no'
        if value == '1' || value == true || value == 'yes' then 'yes' else 'no'
      else if @field()?.kind == 'select_one'
        if value then @field()?.labelFor(value) else ''
      else if @field()?.kind == 'select_many'
        if value then $.map(value, (x) => @field()?.labelFor(x)).join(', ') else ''
      else if @field()?.kind == 'hierarchy'
        if value then @field()?.fieldHierarchyItemsMap[value] else ''
      else if @field()?.kind == 'location'
        if value then @field()?.labelForLocation(value) else ''
      else
        if value then value else ''

    valueUIFrom: (value) =>
      value

    operatorUIForTextField: =>
      [{label: "equal", value: "="}]
    operatorUIForNumericField: =>
      [{label: "equal", value: "="},
       {label: "greater than", value: ">"},
       {label: "greater than or equal", value: ">="},
       {label: "less than", value: "<"},
       {label: "less than or equal", value: "<="}]

    findOperatorByValue: (value)=>
      allOperators = [{label: "equal", value: "="},
             {label: "greater than", value: ">"},
             {label: "greater than or equal", value: ">="},
             {label: "less than", value: "<"},
             {label: "less than or equal", value: "<="}]
      allOperators.filter((x) -> x.value == value)[0]

    toJSON: =>
      id: "#{@id}"
      field_id: "#{@field().id}"
      operator: @operator().value
      value: @value()

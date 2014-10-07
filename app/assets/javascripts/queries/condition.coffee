onQueries ->
  class @Condition
    constructor: (data) ->
      @selectedField = ko.observable(data?.field_id)
      @operator = ko.observable(data?.operator)
      @field = ko.computed => if window.model? && @selectedField()
                                window.model.findFieldById(@selectedField()[0])
      @operatorValue = ko.observable(data?.operatorValue)
      # @field.subscribe =>
      #   if @field()?.kind == 'date'
      #     @startDate = ko.observable()
      #     @endDate = ko.observable()
      #   else
      @fieldValue = ko.observable(data?.field_value)

    toJSON: =>
      field_id: @field().id
      operator: @operator()
      field_value: @fieldValue()     
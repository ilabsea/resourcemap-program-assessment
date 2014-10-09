onQueries ->
  class @Condition
    constructor: (data) ->
      @fieldId = ko.observable(data?.field_id)
      @operator = ko.observable(data?.operator)
      @field = ko.computed => if window.model? && @fieldId()
                                window.model.findFieldById(parseInt(@fieldId()))
      @fieldDateFrom = ko.observable(data?.field_date_from)
      @fieldDateTo = ko.observable(data?.field_date_to)  
      @fieldValue = ko.observable(data?.field_value)
      # @field.subscribe =>
      #   if @field()?.kind == 'date'
      #     @fieldDateFrom = ko.observable(data?.field_date_from)
      #     @fieldDateTo = ko.observable(data?.field_date_to)
      #   else
      #     @fieldValue = ko.observable(data?.field_value)

    toJSON: =>
      if @field()?.kind == 'date'
        field_id: @fieldId()
        operator: @operator()     
        field_date_from: @fieldDateFrom()
        field_date_to: @fieldDateTo()
      else
        field_id: @fieldId()
        operator: @operator()
        field_value: @fieldValue()
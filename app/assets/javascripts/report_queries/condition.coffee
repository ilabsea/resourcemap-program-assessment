onReportQueries ->
  class @Condition
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @fieldId = ko.observable(data?.field_id)
      @operator = ko.observable(data?.operator)
      @field = ko.computed => if window.model? && @fieldId()
                                window.model.findFieldById(parseInt(@fieldId()))
      @fieldDateFrom = ko.observable(data?.field_date_from)
      @fieldDateTo = ko.observable(data?.field_date_to)
      @fieldValue = ko.observable(data?.field_value)

    toJSON: =>
      if @field()?.kind == 'date'
        id: @id()
        field_id: @fieldId()
        operator: @operator()
        field_date_from: @fieldDateFrom()
        field_date_to: @fieldDateTo()
      else
        id: @id()
        field_id: @fieldId()
        operator: @operator()
        field_value: @fieldValue()

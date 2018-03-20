onReportQueries ->
  class @Aggregate
    constructor: (data) ->
      @id = data?.id
      @aggregatorOptions = [
        {label: 'Count', value: 'count'},
        {label: 'Sum', value: 'sum'},
        {label: 'Min', value: 'min'},
        {label: 'Max', value: 'max'},
        {label: 'Average', value: 'avg'}
      ]
      @selectedField = if data?.field_id
                        ko.observableArray([window.model.findFieldById(data.field_id)])
                       else
                         ko.observableArray()
      @field = ko.observable(@selectedField()?[0])

      @aggregator = if data?.aggregator
                    ko.observable(@findAggregatorByValue(data?.aggregator))
                  else
                    ko.observable(data?.aggregator)

      @fieldError = ko.computed => if @hasField() then null else window.t('javascripts.report_queries.the_aggregate_field_must_selected')
      @aggregatorError = ko.computed => if @hasAggregator() then null else window.t('javascripts.report_queries.the_aggregate_field_must_selected')

      @error = ko.computed => @fieldError() || @aggregatorError()
      @valid = ko.computed => !@error()

    hasField: => @field() != ""
    hasAggregator: => @aggregator()?

    findAggregatorByValue: (value)=>
      @aggregatorOptions.filter((x) -> x.value == value)[0]

    toJSON: =>
      id: "#{@id}"
      field_id: "#{@field().id}"
      aggregator: @aggregator().value

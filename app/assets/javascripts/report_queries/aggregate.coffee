onReportQueries ->
  class @Aggregate
    constructor: (data) ->
      @id = data?.id
      @aggregatorOptions = [
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

    findAggregatorByValue: (value)=>
      @aggregatorOptions.filter((x) -> x.value == value)[0]

    toJSON: =>
      id: @id
      field_id: @field().id
      aggregator: @aggregator().value

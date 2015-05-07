onQueries ->
  class @Parse
    constructor: (data) ->
      @conditionId = ko.observable(data?.condition_id)
      @logicalOp = ko.observable(data?.logical_op)
      @left = ko.observable(data?.left)
      @right = ko.observable(data?.right)
      @msg = ko.observable(data?.msg)
      @status = ko.observable data?.status

    toJSON: =>
      condition_id: @conditionId()
      logical_op: @logicalOp()
      left: @left()
      right: @right()
      msg: @msg()
      status: @status()
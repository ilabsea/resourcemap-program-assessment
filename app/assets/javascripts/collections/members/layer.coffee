class @Layer
  constructor: (data) ->
    console.log 'Member Layer'
    @id = ko.observable data?.id
    @name = ko.observable data?.name

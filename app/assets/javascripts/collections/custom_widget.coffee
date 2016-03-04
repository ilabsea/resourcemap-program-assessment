onCollections ->
  class @CustomWidget
    constructor: (field) ->
      @field = field

    bind: ->
      ko.applyBindings(@field, document.getElementById('custom-input-'+@field.code))

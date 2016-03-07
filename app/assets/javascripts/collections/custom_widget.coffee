onCollections ->
  class @CustomWidget
    constructor: (field) ->
      @field = field

    bindWithInput: ->
      ko.applyBindings(@field, document.getElementById('custom-input-'+@field.code))

    bindWithSpan: ->
      ko.applyBindings(@field, document.getElementById('custom-span-'+@field.code))

onCollections ->
  class @CustomWidget
    constructor: (field) ->
      @field = field

    bindWithInput: ->
      # bind if only the field exist in the view
      if $('#custom-input-'+@field.code).length > 0
        ko.applyBindings(@field, document.getElementById('custom-input-'+@field.code))


    bindWithSpan: ->
      # bind if only the field exist in the view
      if $('#custom-span-'+@field.code).length > 0
        ko.applyBindings(@field, document.getElementById('custom-span-'+@field.code))

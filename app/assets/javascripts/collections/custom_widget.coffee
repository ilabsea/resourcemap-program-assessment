onCollections ->
  class @CustomWidget
    constructor: (field) ->
      @field = field

    bindField: ->
      $customWidget = $('#custom-widget-'+@field.code)
      if $customWidget.length > 0
        ko.applyBindings(@field, $customWidget.get(0) )

onCollections ->
  class @CustomWidget
    constructor: (field) ->
      @field = field

    bindField: ->
      $customWidget = $('#custom-widget-'+@field.code)
      console.log 'field : ', @field.code
      console.log 'custom : ', $customWidget
      if $customWidget.length > 0
        console.log 'has custom : ', $customWidget
        ko.applyBindings(@field, $customWidget.get(0) )

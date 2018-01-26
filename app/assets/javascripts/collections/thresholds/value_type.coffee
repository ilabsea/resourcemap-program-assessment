onCollections ->
  class @ValueType
    @VALUE      = new ValueType 'value', window.t('javascripts.plugins.alerts.value_types.a_value_of'), (value) -> value
    @PERCENTAGE = new ValueType 'percentage', window.t('javascripts.plugins.alerts.value_types.a_percentage_of'), (value) -> "#{value}%"

    @ALL        = [ @VALUE, @PERCENTAGE ]

    constructor: (code, label, @format) ->
      @code = ko.observable code
      @label = ko.observable label

    @findByCode: (code) ->
      @[code?.toUpperCase()]

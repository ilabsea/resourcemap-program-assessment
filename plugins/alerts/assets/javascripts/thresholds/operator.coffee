onThresholds ->
  class @Operator
    @LT: -> {code: 'lt', label: window.t('javascripts.plugins.alerts.operators.is_less_than')}
    @GT: -> {code: 'gt', label: window.t('javascripts.plugins.alerts.operators.is_greater_than')}
    @EQ: -> {code: 'eq', label: window.t('javascripts.plugins.alerts.operators.is_equal_to')}
    @EQI: -> {code: 'eqi', label: window.t('javascripts.plugins.alerts.operators.is_equal_to')}
    @CON: -> {code: 'con', label: window.t('javascripts.plugins.alerts.operators.contains')}

    @findByCode: (code) ->
      @[code?.toUpperCase()]() ? @EQ()

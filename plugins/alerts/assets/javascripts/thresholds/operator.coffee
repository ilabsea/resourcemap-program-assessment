onThresholds ->
  class @Operator
    @LT = new Operator('lt', window.t('javascripts.plugins.alerts.operators.is_less_than'))
    @GT = new Operator('gt', window.t('javascripts.plugins.alerts.operators.is_greater_than'))
    @EQ = new Operator('eq', window.t('javascripts.plugins.alerts.operators.is_equal_to'))
    @EQI = new Operator('eqi', window.t('javascripts.plugins.alerts.operators.is_equal_to'))
    @CON = new Operator('con', window.t('javascripts.plugins.alerts.operators.contains'))

    constructor: (code, label) ->
      @code = ko.observable code
      @label = ko.observable label

    @findByCode: (code) ->
      @[code?.toUpperCase()] ? @EQ

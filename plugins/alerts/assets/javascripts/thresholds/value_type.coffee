onThresholds ->
  class @ValueType
    @VALUE: -> {code: 'value', label: window.t('javascripts.plugins.alerts.value_types.a_value_of')}
    @PERCENTAGE: -> {code: 'percentage', label: window.t('javascripts.plugins.alerts.value_types.a_percentage_of')}
    @ALL: -> [@VALUE(), @PERCENTAGE()]

    @format: (code, value) ->
      if code == 'value' then return value
      if code == 'percentage' then return "#{value}%"

    @findByCode: (code) ->
      if code == 'value' then return @VALUE()
      if code == 'percentage' then return @PERCENTAGE()

    @findByLabel: (label) ->
      if label == window.t('javascripts.plugins.alerts.value_types.a_value_of') then return @VALUE()
      if label == window.t('javascripts.plugins.alerts.value_types.a_percentage_of') then return @PERCENTAGE()

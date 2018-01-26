onCollections ->
  class @FieldSelect
    @constructorFieldSelect: (data) ->
      @options = if data.config?.options?
                  $.map data.config.options, (x) => new Option x
                else
                  []
      @optionsIds = $.map @options, (x) => x.id

      # Add the 'no value' option
      @optionsIds.unshift('')
      @optionsUI = [new Option {id: '', label: window.t('javascripts.collections.fields.no_value') }].concat(@options)
      @optionsUIIds = $.map @optionsUI, (x) => x.id

      @hierarchy = @options

    @labelFor: (id) ->
      for option in @optionsUI
        if option.id == id
          return option.label
      null

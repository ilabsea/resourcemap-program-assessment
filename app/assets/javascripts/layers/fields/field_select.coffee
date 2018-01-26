onLayers ->
  class @FieldSelect extends @FieldImpl
    constructor: (field) ->
      super(field)
      @options = if field.config?.options?
                   ko.observableArray($.map(field.config.options, (x) -> new Option(x)))
                 else
                   ko.observableArray()
      @nextId = field.config?.next_id || @options().length + 1
      @error = ko.computed =>
        if @options().length > 0
          codes = []
          labels = []
          for option in @options()
            return window.t('javascripts.layers.fields.errors.duplicated_option_code') + " '#{option.code()}' " + window.t('javascripts.layers.fields.errors.for_field') + " #{@field.name()}" if codes.indexOf(option.code()) >= 0
            return window.t('javascripts.layers.fields.errors.duplicated_option_label') + " '#{option.label()}' " + window.t('javascripts.layers.fields.errors.for_field') + " #{@field.name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          window.t('javascripts.layers.fields.errors.the_field') + " '#{@field.name()}' " + window.t('javascripts.layers.fields.errors.must_have_at_least_one_option')


    addOption: (option) =>
      option.id @nextId
      @options.push option
      @nextId += 1

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId}

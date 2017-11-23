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
            return "duplicated option code '#{option.code()}' for field #{@field.name()}" if codes.indexOf(option.code()) >= 0
            return "duplicated option label '#{option.label()}' for field #{@field.name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          "the field '#{@field.name()}' must have at least one option"


    addOption: (option) =>
      option.id @nextId
      @options.push option
      @nextId += 1

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId}

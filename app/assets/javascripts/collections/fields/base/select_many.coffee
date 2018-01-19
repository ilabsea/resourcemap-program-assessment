onCollections ->
  class @FieldSelectMany
    @constructorFieldSelectMany: (data) ->

      @filter = ko.observable('') # The text for filtering options in a select_many
      @remainingOptions = ko.computed =>
        option.selected(false) for option in @options
        remaining = if @value()
          @options.filter((x) => @value()?.indexOf(x.id) == -1 && x.label.toLowerCase().indexOf(@filter().toLowerCase()) == 0)
        else
          @options.filter((x) => x.label.toLowerCase().indexOf(@filter().toLowerCase()) == 0)
        remaining[0].selected(true) if remaining.length > 0
        remaining

    @expand: -> @expanded(true)

    @filterKeyDown: (model, event) ->
      switch event.keyCode
        when 13 # Enter
          for option, i in @remainingOptions()
            if option.selected()
              @selectOption(option)
              break
          false
        when 38 # Up
          for option, i in @remainingOptions()
            if option.selected() && i > 0
              option.selected(false)
              @remainingOptions()[i - 1].selected(true)
              break
          false
        when 40 # Down
          for option, i in @remainingOptions()
            if option.selected() && i != @remainingOptions().length - 1
              option.selected(false)
              @remainingOptions()[i + 1].selected(true)
              break
          false
        else
          true

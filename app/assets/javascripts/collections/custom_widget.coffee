onCollections ->
  class @CustomWidget
    constructor: (field) ->
      @field = field
      @element = $('#wrapper-custom-widget-'+@field.code)

    bindField: ->
      if @element.length > 0
        if @element.attr("data-readonly") == 'readonly'
          @createReadOnlyElement()
        else
          @createEditableElement()
        ko.applyBindings(@field, @element.get(0) )

    createReadOnlyElement: ->
      if @field.kind == 'numeric' || @field.kind == 'custom_aggregator'
        node = """
              <span data-bind="text: value" id="custom-widget-#{@field.code}" class="custom"></span>
            """
      else if @field.kind == 'select_one'
        node = """
              <span data-bind="text: valueUI" id="custom-widget-#{@field.code}" class="custom"></span>
            """
      @element.append(node)


    createEditableElement: ->
      if @field.kind == 'numeric'
        node = """
                 <input type="text" placeholder="#{@field.code}" name="custom-widget-#{@field.code}"
                        data-bind="value: value, attr: {title: name}" id="custom-widget-#{@field.code}"
                        class="custom key-map-integer" />
               """
      else if @field.kind == 'select_one'
        options = $.map(@field.options, (option, index) ->
                  "<option value=\"#{option['id']}\">#{option['label']}</option>"
                  )
        node = """
                <select data-bind="value: value" id="custom-widget-#{@field.code}">
                  #{options}
                </select>
               """
      @element.append(node)

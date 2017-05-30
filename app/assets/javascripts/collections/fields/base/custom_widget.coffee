onCollections ->
  class @FieldCustomWidget
    @constructorFieldCustomWidget: (data) ->
      @widgetContent = data.config?.widget_content
      @widgetContentViewAsInput = ko.computed =>
        if(@kind == "custom_widget" && @widgetContent != undefined)
          @replaceCustomWidget(@widgetContent)
        else
          ""

      @widgetContentViewAsSpan = ko.computed =>
        if(@kind == "custom_widget" && @widgetContent != undefined)
          @replaceCustomWidget(@widgetContent, true)
        else
          ""

    @replaceCustomWidget: (widgetContent, readonly) ->
      isReadonly = ''
      isReadonly = "data-readonly='readonly'" if readonly == true
      regExp = /(&nbsp;)|\{([^}]*)\}/g
      widget = widgetContent.replace(regExp, (match, space, token)->
        replace = space || token
        if replace == "&nbsp;"
          replaceBy = ''
        else
          replaceBy = """
                      <span id="wrapper-custom-widget-#{replace}" #{isReadonly}></span>
                      """
        return replaceBy
       )

    @bindWithCustomWidgetedField: ->
      if @kind == 'custom_widget' && @widgetContent
        arr_field_wrapper = @widgetContentViewAsInput().match(/wrapper-custom-widget-[^"]+/g)
        if arr_field_wrapper.length > 0
          for field_wrapper in arr_field_wrapper
            field_code = field_wrapper.split("wrapper-custom-widget-")[1]
            field = window.model.findFieldByCode(field_code)
            new CustomWidget(field).bindField()

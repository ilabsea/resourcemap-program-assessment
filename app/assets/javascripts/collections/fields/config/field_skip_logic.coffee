onCollections ->
  class @FieldSkipLogic
    @constructorFieldSkipLogic: (data) ->
      @is_enable_field_logic = data.is_enable_field_logic
      @field_logics = if data.config?.field_logics?
                          $.map data.config.field_logics, (x) => new FieldLogic x
                        else
                          []
      @skippedState = ko.observable(false)
      @is_blocked_by = ko.observableArray([])

      @blocked = ko.computed =>
        field_object = @get_dom_object(this)
        if @hasBlockedBy()
          field_object.block({message: ""})
        else
          field_object.unblock()

    @hasBlockedBy: ->
      @is_blocked_by() != undefined and @is_blocked_by().length > 0

    @refresh_skip: ->
      if(@is_blocked_by().length > 0)
        tmp = @is_blocked_by()
        @is_blocked_by(tmp)


    @disableDependentSkipLogicField: ->
      if window.model.editingSite()
        fieldSkipIds = @getRelatedSkipFieldIds()
        for field_id in fieldSkipIds
          field = window.model.editingSite().findFieldByEsCode(field_id)
          skipFlag = false
          for field_logic in field.field_logics
            dependentField = window.model.editingSite().findFieldByEsCode(field_logic.field_id)
            skipFlag = field_logic.isSkip(dependentField)
            if skipFlag == true
              @disableField(field)
              break
          if(skipFlag == false)
            @enableField(field)

    @getRelatedSkipFieldIds: ->
      fieldSkipIds = []
      for field_logic in @relatedFieldLogics()
        if(fieldSkipIds.indexOf(field_logic.disable_field_id) == -1)
          fieldSkipIds.push field_logic.disable_field_id
      return fieldSkipIds

    #current field might be the dependentField of other field_logic
    #the disableField of that field_logic might have many related field_logics
    @relatedFieldLogics: ->
      if model.allFieldLogics().length > 0
        return model.allFieldLogics().filter((x) => "#{x.field_id}" == "#{@esCode}")
      return []

    @disableField: (field) ->
      field.is_mandatory(false)
      field.errorMessage('')
      field.skippedState(true)
      field.is_blocked_by([@])
      field.value(null)

    @get_dom_object: (field) ->
      switch field.kind
        when 'select_one'
          field.value('')
          field_id = field.kind + "-input-" + field.code
          field_object = $("#" + field_id).parent()
        when 'select_many'
          if field.expanded()
            field_id = "select-many-input-" + field.code
            field_object = $("#" + field_id).parent().parent()
          else
            field.expanded(true)
            field_id = "select-many-input-" + field.code
            field_object = $("#" + field_id).parent().parent()
            field.expanded(false)

        when 'hierarchy'
          field_id = field.esCode
          field_object = $("#" + field_id).parent()
        when 'date'
          field_id = "date-input-" + field.esCode
          field_object = $("#" + field_id).parent()
        when 'photo'
          field_id = field.code
          field_object = $("#" + field_id).parent()
        when 'custom_widget'
          field_object = $("#custom_widget-wrapper-"+field.code)
        else
          field_id = field.kind + "-input-" + field.code
          field_object = $("#" + field_id).parent()
      field_object

    @enableField: (field) =>
      field.skippedState(false)
      field.is_mandatory(field.originalIsMandatory)
      field.valid()
      field.is_blocked_by([]) if field.hasBlockedBy()

    @inititalFieldLogic: ->
      for f in @field_logics
        f["disable_field_id"] = @esCode
        window.model.allFieldLogics(window.model.allFieldLogics().concat(f))

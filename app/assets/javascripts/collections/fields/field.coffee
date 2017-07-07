#= require module
#= require collections/fields/base/select
#= require collections/fields/base/select_many
#= require collections/fields/base/hierarchy
#= require collections/fields/base/location
#= require collections/fields/base/photo
#= require collections/fields/base/calculation
#= require collections/fields/base/custom_widget
#= require collections/fields/config/field_skip_logic
#= require collections/fields/config/field_validation

onCollections ->

  # A Layer field
  class @Field extends Module

    @include FieldSelect
    @include FieldSelectMany
    @include FieldHierarchy
    @include FieldLocation
    @include FieldPhoto
    @include FieldCalculation
    @include FieldCustomWidget
    @include FieldSkipLogic
    @include FieldValidation

    constructor: (data, layerId) ->
      @layer_id = layerId
      @esCode = "#{data.id}"
      @code = data.code
      @name = data.name
      @kind = data.kind
      @ord = data.ord
      @preKeyCode = null

      @showInGroupBy = @kind in ['select_one', 'select_many', 'hierarchy']
      @writeable = @originalWriteable = data?.writeable
      @allowsDecimals = ko.observable data?.config?.allows_decimals == 'true'
      @is_mandatory = ko.observable data?.is_mandatory ? false
      @originalIsMandatory = data.is_mandatory
      @keyType = if @allowsDecimals() then 'decimal' else 'integer'
      @editing = ko.observable false
      @expanded = ko.observable false
      @is_display_field = ko.observable data?.is_display_field ? false
      @invisible = ko.computed => if @kind == "calculation" && !@is_display_field()
                                    return "invisible-div"

      @isForCustomWidget = data.custom_widgeted
      @is_enable_dependancy_hierarchy = ko.observable data?.is_enable_dependancy_hierarchy ? false
      @filter = ->

      @value = ko.observable()
      @value.subscribe =>
        @disableDependentSkipLogicField()
        @performCalculation()
        @updateDependentFieldsHierarchyItemList()

      @valueUI =  ko.computed
       read: =>  @valueUIFor(@value())
       write: (value) =>
         @value(@valueUIFrom(value))

      @errorMessage = ko.observable()
      @error = ko.computed => !!@errorMessage()
      @errorClass = ko.computed => if @error() then 'error' else '' # For field number

      @constructorFieldSelect(data) #if @kind in ['select_one', 'select_many']
      @constructorFieldSelectMany(data) if @kind == 'select_many'
      @constructorFieldHierarchy(data) if @kind == 'hierarchy'
      @constructorFieldLocation(data) if @kind == 'location'
      @constructorFieldPhoto(data) if @kind == 'photo'
      @constructorFieldCalculation(data) if @kind == 'calculation'
      @constructorFieldCustomWidget(data) if @kind == 'custom_widget'
      @constructorFieldSkipLogic(data)
      @constructorFieldValidation(data)


    setValueFromSite: (value) =>
      if @kind == 'date' && $.trim(value).length > 0
        # Value from server comes with utc time zone and creating a date here gives one
        # with the client's (browser) time zone, so we convert it back to utc
        date = new Date(value)
        date.setTime(date.getTime() + date.getTimezoneOffset() * 60000)
        value = @datePickerFormat(date)
      else if @kind == 'numeric' || @kind == 'calculation'
        value = @valueUIFor(value)

      value = '' if (value == null && value == '')

      @value(value)

    codeForLink: (api = false) =>
      if api then @code else @esCode

    # The value of the UI.
    # If it's a select one or many, we need to get the label from the option code.
    valueUIFor: (value) =>
      if @kind == 'yes_no'
        if value then window.t('javascripts.collections.fields.yes') else window.t('javascripts.collections.fields.no')
      else if @kind == 'select_one'
        if value then @labelFor(value) else ''
      else if @kind == 'location'
        if value then @labelForLocation(value) else ''
      else if @kind == 'select_many'
        if value then $.map(value, (x) => @labelFor(x)).join(', ') else ''
      else if @kind == 'hierarchy'
        if value then @fieldHierarchyItemsMap[value] else ''
      else if @kind == 'site'
        name = window.model.currentCollection()?.findSiteNameById(value)
        if value && name then name else ''
      else if @kind == 'calculation' || @kind == 'numeric'
        if value != null && value != '' && value != 'NaN' && typeof value != 'undefined'
          if @digitsPrecision
            value = parseFloat(value)
            Number((value).toFixed(parseInt(@digitsPrecision)))
          else
            value
        else
          ''
      else
        if value != null && value != '' && typeof value != 'undefined' then value else ''

    valueUIFrom: (value) =>
      if @kind == 'site'
        # Return site_id or "" if the id for this name is not found (deleting the value or invalid value)
        window.model.currentCollection()?.findSiteIdByName(value) || ""
      else
        value

    selectOption: (option) =>
      @value([]) unless @value()
      @value().push(option.id)
      @value.valueHasMutated()
      @filter('')

    removeOption: (optionId) =>
      @value([]) unless @value()
      @value(arrayDiff(@value(), [optionId]))
      @value.valueHasMutated()

    datePickerFormat: (date) =>
      month = date.getMonth() + 1
      date.getDate() + '/' + month + '/' + date.getFullYear()

    edit: =>
      @editing(true)
      if !window.model.currentCollection()?.currentSnapshot
        @originalValue = @value()

        # For select many, if it's an array we need to duplicate it
        if @kind == 'select_many' && typeof(@) == 'object'
          @originalValue = @originalValue.slice(0)

        @editing(true)
        optionsDatePicker = {}
        optionsDatePicker.onSelect = (dateText) =>
          @valueUI(dateText)
          @save()
        optionsDatePicker.onClose = () =>
          @save()
        window.model.initDatePicker(optionsDatePicker)
        window.model.initAutocomplete()
        window.model.initControlKey()

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else
          if field.kind == "numeric"
            if field.allowsDecimals()
              return @validate_digit(event.keyCode)
          return true

    exit: =>
      @value(@originalValue)
      @editing(false)
      @filter('')
      delete @originalValue

    save: =>
      window.model.editingSite().updateProperty(@esCode, @value())
      if !@error()
        @editing(false)
        @filter('')
        delete @originalValue

    closeDatePickerAndSave: =>
      if $('#ui-datepicker-div:visible').length == 0
        @save()

    # In the table view, use a fixed size width for each property column,
    # which depends on the length of the name.
    suggestedWidth: =>
      if @name.length < 10
        '100px'
      else
        "#{20 + @name.length * 8}px"

    isPluginKind: => -1 isnt PLUGIN_FIELDS.indexOf @kind

    exitEditing: ->
      @resultLocations(@locations) if @kind == 'location'

      @editing(false)
      @writeable = @originalWriteable

    inputable: =>
      if (@kind == 'custom_widget' && @readonly_custom_widgeted == true) || @isForCustomWidget
        false
      else
        true

    visible: =>
      if (@kind != "calculation" || (@kind == "calculation" && @is_display_field)) && !@isForCustomWidget
        true
      else
        false
    init: =>
      if @kind == 'date'
        window.model.initDatePicker()

    isShowingNonValue: =>
      return false if @kind == 'custom_widget'
      return true

    isAllowSingleEditMode: =>
      return (@kind not in ['photo', 'custom_widget']) &&
             (!@isDependentFieldHierarchy())

#= require module
#= require collections/fields/base/numeric
#= require collections/fields/base/yes_no
#= require collections/fields/base/select
#= require collections/fields/base/select_many
#= require collections/fields/base/hierarchy
#= require collections/fields/base/location
#= require collections/fields/base/photo
#= require collections/fields/base/calculation
#= require collections/fields/base/custom_widget
#= require collections/fields/config/field_skip_logic

onCollections ->

  # A Layer field
  class @Field extends Module

    @include FieldNumeric
    @include FieldYesNo
    @include FieldSelect
    @include FieldSelectMany
    @include FieldHierarchy
    @include FieldLocation
    @include FieldPhoto
    @include FieldCalculation
    @include FieldCustomWidget
    @include FieldSkipLogic

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
      @config = ko.observable data?.config
      @is_mandatory = ko.observable data?.is_mandatory ? false
      @is_display_field = ko.observable data?.is_display_field ? false
      @invisible = ko.computed => if @kind == "calculation" && !@is_display_field()
                                    return "invisible-div"
      @isForCustomWidget = data.custom_widgeted
      @is_enable_dependancy_hierarchy = ko.observable data?.is_enable_dependancy_hierarchy ? false
      @originalIsMandatory = data.is_mandatory
      @allowsDecimals = ko.observable data?.config?.allows_decimals == 'true'

      @editing = ko.observable false
      @expanded = ko.observable false

      @value = ko.observable()
      @value.subscribe =>
        @valid()
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

      @hasValue = ko.computed =>
        if @kind == 'yes_no'
          true
        else if @kind == 'select_many'
          @value() && @value().length > 0
        else if @kind == 'numeric'
          @value() != '' && @value() != null && @value() != undefined
        else
          @value()
      @constructorFieldNumeric(data) if @kind == 'numeric'
      @constructorFieldYesNo(data) if @kind == 'yes_no'
      @constructorFieldSelect(data)
      @constructorFieldSelectMany(data) if @kind == 'select_many'
      @constructorFieldHierarchy(data) if @kind == 'hierarchy'
      @constructorFieldLocation(data) if @kind == 'location'
      @constructorFieldPhoto(data) if @kind == 'photo'
      @constructorFieldCalculation(data) if @kind == 'calculation'
      @constructorFieldCustomWidget(data) if @kind == 'custom_widget'
      @constructorFieldSkipLogic(data)

    valid: =>
      fieldValidator = new FieldValidator(@)
      fieldValidator.validateMandatory()
      fieldValidator.validateFormat()
      fieldValidator.validateRangeAndDigitsPrecision()
      fieldValidator.validateCustomValidation()

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

    buildCompareFieldConfigOfCustomValidation: (fieldId, operator, compareField) =>
      compare = {
        field_id: fieldId,
        condition_type: operator
      }
      if ( compareField.config().compare_custom_validations )
        compareField.config().compare_custom_validations.push(compare)
      else
        compareField.config().compare_custom_validations = [compare]

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
      day = date.getDate()
      day = if day < 10 then '0'+day else day

      month = date.getMonth() + 1
      month = if month < 10 then '0'+month else month

      day + '/' + month + '/' + date.getFullYear()

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

    validate_integer_only: (keyCode) =>
      value = $('#'+@kind+'-input-'+@code).val()
      if value == null || value == ""
        if(keyCode == 189 || keyCode == 173) && (@preKeyCode != 189 || @preKeyCode == null || @preKeyCode == 173) #allow '-' for both chrome & firefox
          @preKeyCode = keyCode
          return true
      else
        if(keyCode == 189 || keyCode == 173) && value.charAt(0) != '-'
          @preKeyCode = keyCode
          return true
      if keyCode > 31 && (keyCode < 48 || keyCode > 57) && (keyCode != 8 && keyCode != 46) && keyCode != 37 && keyCode != 39  #allow right and left arrow key
        return false
      else
        @preKeyCode = keyCode
        return true

    validate_decimal_key: (keyCode) =>
      value = ''
      if @isForCustomWidget
        value = $('#custom-widget-'+@code).val()
      else
        value = $('#'+@kind+'-input-'+@code).val()
      dotcontains = value.indexOf(".") != -1
      if (dotcontains)
        if (keyCode == 190)
          return false

      if (keyCode == 190)
        return true

      if (keyCode > 31 && (keyCode < 48 || keyCode > 57))
        return false
      return true

    validate_number_key: (keyCode) =>
      if keyCode > 31 && (keyCode < 48 || keyCode > 57)
        return false
      return true

    keyPress: (field, event) =>
      switch event.keyCode
        when 13 then @save()
        when 27 then @exit()
        else
          if field.kind == "numeric"
            if field.allowsDecimals()
              return @validate_decimal_key(event.keyCode)
            else
              return @validate_number_key(event.keyCode)
          return true

    exit: =>
      @value(@originalValue)
      @editing(false)
      @filter('')
      delete @originalValue

    save: (obj, event)=>
      window.model.editingSite().updateProperty(@esCode, @value())
      if !@error()
        @editing(false)
        @filter('') if @kind == 'select_many'
        new FieldValidator(@).validateMandatory() #re-validate mandatory
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
      if window.model.newOrEditSite() && @kind == 'numeric' && @is_enable_custom_validation
        if @configCustomValidations()
          $.map(@configCustomValidations(), (c) =>
            compareField = window.model.newOrEditSite().findFieldByEsCode(c.field_id[0])
            @buildCompareFieldConfigOfCustomValidation(@esCode, c.condition_type, compareField)
          )

    isShowingNonValue: =>
      return false if @kind == 'custom_widget'
      return true

    isAllowSingleEditMode: =>
      return (@kind not in ['photo', 'custom_widget']) &&
             (!@isDependentFieldHierarchy())

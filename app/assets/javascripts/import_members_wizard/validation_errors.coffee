onImportMembersWizard ->
  class @ValidationErrors
    constructor: (data) ->
      #private variables
      @errors = data
      @errorsByType = @processErrors()

    hasErrors: =>
      for errorKey,errorValue of @errors
        return true unless $.isEmptyObject(errorValue)
      return false

    summarizedErrorList: =>
      $.map @errorsByType, (e) => {description: e.description, more_info: e.more_info}

    errorsForColumn: (column_index) =>
      (error for error in @errorsByType when $.inArray(column_index, error.columns) != -1)

    processErrors: =>
      errorsByType = []
      for errorType,errors of @errors
        if !$.isEmptyObject(errors)
          errorIndex = $.map(errors, (f) => f = f + 1)
          errorColumns =  errorIndex.join(",")
          error_description = {error_kind: errorType, columns: errorColumns}
          switch errorType
            when 'missing_email'
              error_description.description = "There are some email not registered in they system"
              error_description.more_info = "Columns Email on row #{errorColumns} have the email not registered as user in the system. To fix this issue, please change the email to registered user."
            when 'duplicated_email'
              error_description.description = "There is more than one column with email duplicated."
              error_description.more_info = "Columns #{errorColumns} have the same email. To fix this issue, leave only one with that email and modify the rest."
            when 'existed_email'
              error_description.description = "There is more than one column with email already registered to the system."
              error_description.more_info = "Columns #{errorColumns} have email that not refered to registered user. To fix this issue, please only use email of registered user only."
          errorsByType.push(error_description)
      errorsByType


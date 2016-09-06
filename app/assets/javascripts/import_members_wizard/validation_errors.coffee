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

    toIndex1BasedSentence: (index_array) =>
      index_array = $.map index_array, (index) => index + 1
      window.toSentence(index_array)

    summarizedErrorList: =>
      $.map @errorsByType, (e) => {description: e.description, more_info: e.more_info}

    errorsForColumn: (column_index) =>
      (error for error in @errorsByType when $.inArray(column_index, error.columns) != -1)

    processErrors: =>
      errorsByType = []
      for errorType,errors of @errors
        if !$.isEmptyObject(errors)
          for errorId, errorColumns of errors
            error_description = {error_kind: errorType, columns: errorColumns}
            switch errorType
              when 'missing_email'
                error_description.description = "Please select a column to be used as 'Name'"
                error_description.more_info = "You need to select a column to be used as 'Email' of the member in order to continue with the upload."
              when 'duplicated_email'
                error_description.description = "There is more than one column with email '#{errorId}'."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} have the same email. To fix this issue, leave only one with that email and modify the rest."
              when 'not_existed_email'
                error_description.description = "There is more than one column with email '#{errorId}'."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} have email that not refered to registered user. To fix this issue, please only use email of registered user only."
            errorsByType.push(error_description)
      errorsByType


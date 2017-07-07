onCollections ->
  class @FieldCalculation
    @constructorFieldCalculation: (data) ->
      @digitsPrecision = data?.config?.digits_precision
      @codeCalculation = data.config?.code_calculation
      @dependentFields = data.config?.dependent_fields

    @performCalculation: ->
      $ele = new FieldView(@).domObject()
      calculationIds = $ele.attr('data-calculation-ids')?.split(",") ? []
      for calculationId in calculationIds
        window.model.newOrEditSite().updateField(calculationId)

onCollections ->
  class @QueryCondition
  	constructor: (data) ->
      @fieldId = data?.field_id
      @operator = data?.operator
      @collection = window.model.currentCollection()
      @field = @collection.findFieldByEsCode(@fieldId)
      if @field?.kind == 'date'
	      @fieldDateFrom = data?.field_date_from
	      @fieldDateTo = data?.field_date_to
      else
        @fieldValue = data?.field_value  
   
#= require thresholds/on_thresholds
#= require_tree

# We do the check again so tests don't trigger this initialization
onThresholds -> if $('#thresholds-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/thresholds/)
  collectionId = parseInt(match[1])

  supportedKinds = ['text', 'numeric', 'yes_no', 'select_one', 'date', 'email', 'phone']
  supportedKindForMessageTemplate = ['text', 'numeric', 'yes_no', 'select_one', 'date', 'email', 'phone', 'hierarchy', 'calculation']

  window.model = new MainViewModel(collectionId)
  ko.applyBindings window.model

  $.get "/collections/#{collectionId}.json", (collection) ->
    window.model.collectionIcon = collection.icon

  #show loading
  $('#loadProgress').show()

  $.get "/collections/#{collectionId}/fields.json", (layers) ->
    fieldListForMessageTemplate = []
    for layer in layers
      tmpFields = $.map(layer.fields, (field) -> new Field(field) if field.kind in supportedKindForMessageTemplate)
      fieldListForMessageTemplate = fieldListForMessageTemplate.concat tmpFields
      layer.fields = $.map(layer.fields, (field) -> new Field(field) if !!~supportedKinds.indexOf field.kind)

    fields = $.map(layers, (layer) -> layer.fields)

    window.model.layers layers
    window.model.compareFields fields
    window.model.fields fields
    window.model.fieldListForMessageTemplate fieldListForMessageTemplate

    $.get "/plugin/alerts/collections/#{collectionId}/thresholds.json", (thresholds) ->
      thresholds = $.map thresholds, (threshold) -> new Threshold threshold, window.model.collectionIcon
      window.model.thresholds thresholds
      window.model.isReady(true)
      $('#loadProgress').hide() #hide loading

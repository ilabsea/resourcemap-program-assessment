#= require queries/on_queries
#= require_tree ./queries/.

# We do the check again so tests don't trigger this initialization
onQueries -> if $('#queries-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/queries/)
  collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  window.model = new MainViewModel(collectionId)
  ko.applyBindings window.model
  
  $.get "/collections/#{collectionId}/layers.json", {}, (layers) ->
    layers = $.map layers, (layer) -> new Layer layer
    window.model.layers(layers)
    $.get "/collections/#{collectionId}/queries.json", {}, (queries) ->
      queries = $.map queries, (query) -> new Query(query)
      window.model.queries(queries)      
      $('.hidden-until-loaded').show()

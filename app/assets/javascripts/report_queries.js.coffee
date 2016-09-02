#= require report_queries/on_report_queries
#= require_tree ./report_queries/.

# We do the check again so tests don't trigger this initialization
onReportQueries -> if $('#report-queries-main').length > 0
  match = window.location.toString().match(/\/collections\/(\d+)\/report_queries/)
  collectionId = parseInt(match[1])

  $('.hierarchy_upload').live 'change', ->
    $('.hierarchy_form').submit()
    window.model.startUploadHierarchy()

  window.model = new MainViewModel(collectionId)
  ko.applyBindings window.model

  #show loading
  $('#loadProgress').show()

  $.get "/collections/#{collectionId}/layers.json", {}, (layers) ->
    layers = $.map layers, (layer) -> new Layer layer
    window.model.layers(layers)
    $.get "/collections/#{collectionId}/report_queries.json", {}, (report_queries) ->
      reportQueries = $.map report_queries, (query) -> new ReportQuery(query)
      window.model.reportQueries(reportQueries)
      $('.hidden-until-loaded').show()
      $('#loadProgress').hide() #hide loading

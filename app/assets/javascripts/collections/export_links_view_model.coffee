onCollections ->

  class @ExportLinksViewModel
    @exportInRSS: -> @export 'rss'

    @exportInSHP: -> @export 'shp'

    @exportInJSON: -> @export 'json'

    @exportInKML: -> @export 'kml'

    @exportInCSV: -> @export 'csv'

    @export: (format) ->
     $.ajax '/get_user_auth_token',
      type: 'GET'
      error: (jqXHR, textStatus, errorThrown) ->
        window.location.href = '/users/sign_in'
      success: (data, textStatus, jqXHR) ->
        window.open(window.model.currentCollection().link(format, data))

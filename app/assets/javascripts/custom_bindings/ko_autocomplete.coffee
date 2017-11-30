ko.bindingHandlers.ko_autocomplete =
  init: (element, params) ->
    $(element).autocomplete params()
    return
  update: (element, params) ->
    $(element).autocomplete 'option', 'source', params().source
    return

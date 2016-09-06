#= require import_members_wizard/on_import_members_wizard
#= require_tree ./import_members_wizard/.

# We do the check again so tests don't trigger this initialization
onImportMembersWizard -> if $('#import-members-wizard-main').length > 0

  match = window.location.toString().match(/\/collections\/(\d+)\/import_wizard/)
  collectionId = parseInt(match[1])
  $.get "/collections/#{collectionId}/import_wizard/get_columns_members_spec.json", {}, (columns) =>
    window.model = new MainViewModel
    window.model.initialize collectionId, columns, window.kinds

    ko.applyBindings window.model

    $.post "/collections/#{collectionId}/import_wizard/validate_members_with_columns.json", {columns: JSON.stringify(columns)}, (preview) =>
      window.model.loadMembers(preview)
      $('#generating_preview').hide()
      $('h2').removeClass('loading')
      $('.hidden-until-loaded').show()
      $("a.fancybox").fancybox({
        minWidth: '450px',
        onClosed: ->
          window.model.selectedColumn().discardAndClose()
      })

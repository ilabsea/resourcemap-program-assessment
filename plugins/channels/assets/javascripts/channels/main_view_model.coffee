onChannels ->
  class @MainViewModel
    constructor: (@collectionId)->
      @gateways         = ko.observableArray()
      @selectedGateways = ko.observableArray()
      @collectionId     = ko.observable @collectionId 
    
    saveChannel: =>
      $.post "/collections/#{@collectionId()}/register_gateways.json", gateways: @selectedGateways(), @saveChannelCallback

    saveChannelCallback: (data) =>
      $.status.showNotice(window.t('javascripts.gateways.successfully_setting_sms_gateways'), 2000)

@initMemberships = (userId, collectionId, layers) ->
  window.userId = userId

  class Expandable
    constructor: ->
      @expanded = ko.observable false

    toggleExpanded: => @expanded(!@expanded())

  class LayerMembership
    constructor: (data) ->
      @layerId = ko.observable data.layer_id
      @read = ko.observable data.read
      @write = ko.observable data.write

  class Layer extends Expandable
    constructor: (data) ->
      super
      @id = ko.observable data?.id
      @name = ko.observable data?.name

    initializeLinks: =>
      @membershipLayerLinks = ko.observableArray $.map(window.model.memberships(), (x) => new MembershipLayerLink(x, @))

  class MembershipLayerLink
    constructor: (membership, layer) ->
      @membership = membership
      @layer = layer

      @canRead = ko.computed
        read: =>
          if @membership.admin()
            true
          else
            @membership.findLayerMembership(@layer)?.read()
        write: (value) =>
          $.post "/collections/#{collectionId}/memberships/#{@membership.userId()}/set_layer_access.json", {layer_id: @layer.id(), verb: 'read', access: value}, =>
            lm = @membership.findLayerMembership(@layer)
            if lm
              lm.read value
            else
              @membership.layers().push new LayerMembership(layer_id: @layer.id(), read: value, write: false)
              @membership.layers.valueHasMutated()
        owner: @

      @canWrite = ko.computed
        read: =>
          if @membership.admin()
            true
          else
            @membership.findLayerMembership(@layer)?.write()
        write: (value) =>
          $.post "/collections/#{collectionId}/memberships/#{@membership.userId()}/set_layer_access.json", {layer_id: @layer.id(), verb: 'write', access: value}, =>
            lm = @membership.findLayerMembership(@layer)
            if lm
              lm.write value
            else
              @membership.layers().push new LayerMembership(layer_id: @layer.id(), read: false, write: value)
              @membership.layers.valueHasMutated()
        owner: @

      @canReadUI = ko.computed => if @canRead() then "Yes" else "No"
      @canWriteUI = ko.computed => if @canWrite() then "Yes" else "No"

  class Membership extends Expandable
    constructor: (data) ->
      super
      @userId = ko.observable data?.user_id
      @userDisplayName = ko.observable data?.user_display_name
      @admin = ko.observable data?.admin
      @layers = ko.observableArray $.map(data?.layers ? [], (x) => new LayerMembership(x))

      @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
      @isCurrentUser = ko.computed => window.userId == @userId()

    initializeLinks: =>
      @membershipLayerLinks = ko.observableArray $.map(window.model.layers(), (x) => new MembershipLayerLink(@, x))

    findLayerMembership: (layer) =>
      lm = @layers().filter((x) -> x.layerId() == layer.id())
      if lm.length > 0 then lm[0] else null

  class MembershipsViewModel
    initialize: (memberships, layers) ->
      @selectedLayer = ko.observable()
      @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))
      @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(x))

      layer.initializeLinks() for layer in @layers()
      membership.initializeLinks() for membership in @memberships()

      @groupBy = ko.observable("Users")
      @groupByOptions = ["Users", "Layers"]

    destroyMembership: (membership) =>
      if confirm("Are you sure you want to remove #{membership.userDisplayName()} from the collection?")
        $.post "/collections/#{collectionId}/memberships/#{membership.userId()}.json", {_method: 'delete'}, =>
          @memberships.remove membership

  $.get "/collections/#{collectionId}/memberships.json", (memberships) ->
    window.model = new MembershipsViewModel
    window.model.initialize memberships, layers
    ko.applyBindings window.model

    $member_email = $('#member_email')

    createMembership = (email = $member_email.val()) ->
      if $.trim(email).length > 0
        $.post "/collections/#{collectionId}/memberships.json", {email: email}, (data) ->
          if data.status == 'added'
            window.model.memberships.push new Membership(user_id: data.user_id, user_display_name: data.user_display_name)
            $member_email.val('')

    $member_email.autocomplete
      source: "/collections/#{collectionId}/memberships/invitable.json"
      select: (event, ui) -> createMembership(ui.item.label)

    $member_email.keydown (event) ->
      if event.keyCode == 13
        createMembership()

    $('#add_member').click -> createMembership()

$ -> 
  module 'rm'

  rm.MembersViewModel = class MembersViewModel 
    initialize: (userId, collectionId, admin, layers) ->
      window.userId = userId

      $.get "/collections/#{collectionId}/memberships.json", (memberships) ->
        window.model = new rm.MembersViewModel
        window.model.membersViewModel admin, memberships, layers
        ko.applyBindings window.model

        $('.hidden-until-loaded').show()

    membersViewModel: (admin, memberships, layers) ->
      @selectedLayer = ko.observable()
      @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))
      @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(x))
      @admin = ko.observable admin

      @groupBy = ko.observable("Users")
      @groupByOptions = ["Users", "Layers"]

    class Expandable
      constructor: ->
        @expanded = ko.observable false

      toggleExpanded: => @expanded(!@expanded())

    class LayerMembership
      constructor: (data) ->
        @layerId = ko.observable data.layer_id
        @read = ko.observable data.read
        @write = ko.observable data.write

    class Membership extends Expandable
      constructor: (data) ->
        super
        @userId = ko.observable data?.user_id
        @userDisplayName = ko.observable data?.user_display_name
        @admin = ko.observable data?.admin
        @layers = ko.observableArray $.map(data?.layers ? [], (x) => new LayerMembership(x))

        @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
        @isCurrentUser = ko.computed => window.userId == @userId()

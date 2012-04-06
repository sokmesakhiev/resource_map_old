#= require models/member
$ -> 
  module 'rm'

  rm.MembersViewModel = class MembersViewModel 
    constructor: (collectionId, admin, layers) ->
      @param_collectionId = collectionId
      @param_admin = admin
      @param_layers = layers
    
    viewModel: (admin, memberships, layers) ->
      @selectedLayer = ko.observable()
      @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))
      @memberships = ko.observableArray $.map(memberships, (x) -> new rm.Member(x))
      @admin = ko.observable admin

      @groupBy = ko.observable("Users")
      @groupByOptions = ["Users", "Layers"]


$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.collectionsViewModel = new rm.CollectionsViewModel

  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    ko.applyBindings rm.collectionsViewModel

    $.getJSON '/collections.json', (data) ->
      collections = $.map data, (collection) -> new rm.Collection collection
      rm.collectionsViewModel.collections collections

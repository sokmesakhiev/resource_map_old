$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.collectionsViewModel = new rm.CollectionsViewModel

  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    ko.applyBindings rm.collectionsViewModel

    $.getJSON '/collections.json', (data) ->
      collections = $.map data, (collection) -> new rm.Collection collection
      rm.collectionsViewModel.collections collections

      # load map
      mapOptions =
        center: new google.maps.LatLng(10, 90)
        zoom: 4
        mapTypeId: google.maps.MapTypeId.ROADMAP
      rm.EventDispatcher.trigger rm.GoogleMapsEvent.LOAD, new rm.GoogleMapsEvent mapOptions

$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.googleMapsApi = new rm.GoogleMapsApi

  rm.EventDispatcher.bind rm.GoogleMapsEvent.LOAD, (event) ->
    rm.googleMapsApi.initMap event.data.lat, event.data.lng

  rm.EventDispatcher.bind rm.GoogleMapsEvent.BOUNDS_CHANGED, (event) ->
    query = event.data.bounds
    query.collection_ids = $.map rm.collectionsViewModel.collections(), (c) -> c.id()

    $.getJSON '/sites/search.json', query, (data) ->
      rm.googleMapsApi.populate data

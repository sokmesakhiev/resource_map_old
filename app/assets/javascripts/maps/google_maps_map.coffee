$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.googleMapsApi = new rm.GoogleMapsApi

  rm.EventDispatcher.bind rm.GoogleMapsEvent.LOAD, (event) ->
    rm.googleMapsApi.initMap event.lat, event.lng

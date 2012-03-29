$ ->
  module 'rm'

  rm.EventDispatcher.bind rm.GoogleMapsEvent.LOAD, (event) ->
    rm.googleMapsApi = new GoogleMapsApi event.mapOptions

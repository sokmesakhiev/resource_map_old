$ ->
  module 'rm'

  rm.GoogleMapsApi = class GoogleMapsApi

    @ElementId = 'map'
    @Zoom = 4
    @Lat = 10
    @Lng = 90
    
    initMap: (lat, lng) ->
      lat ?= GoogleMapsApi.Lat
      lng ?= GoogleMapsApi.Lng

      canvas = document.getElementById GoogleMapsApi.ElementId
      mapOptions =
        center    : new google.maps.LatLng lat, lng
        zoom      : GoogleMapsApi.Zoom
        mapTypeId : google.maps.MapTypeId.ROADMAP

      @map = new google.maps.Map canvas, mapOptions

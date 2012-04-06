#= require models/cluster

$ ->
  module 'rm'

  rm.GoogleMapsApi = class GoogleMapsApi

    @ElementId = 'map'
    @Zoom = 4
    @Lat = 10
    @Lng = 90

    constructor: ->
      @markers = {}
      @clusters = {}

    initMap: (lat, lng) ->
      lat ?= GoogleMapsApi.Lat
      lng ?= GoogleMapsApi.Lng

      canvas = document.getElementById GoogleMapsApi.ElementId
      mapOptions =
        center    : new google.maps.LatLng lat, lng
        zoom      : GoogleMapsApi.Zoom
        mapTypeId : google.maps.MapTypeId.ROADMAP

      @map = new google.maps.Map canvas, mapOptions
      @_onBoundsChanged()

    populate: (data) ->
      @_clearMap()
      @_populateMarkers data?.sites
      @_populateClusters data?.clusters

    createMarker: (lat, lng) ->
      mapOptions =
        map: @map
        position: new google.maps.LatLng lat, lng

      new google.maps.Marker mapOptions

    _onBoundsChanged: ->
      listener = google.maps.event.addListener @map, 'bounds_changed', =>
        google.maps.event.removeListener listener
        @_triggerBoundsChanged()

      google.maps.event.addListener @map, 'dragend', => @_triggerBoundsChanged()
      google.maps.event.addListener @map, 'zoom_changed', =>
        listener2 = google.maps.event.addListener @map, 'bounds_changed', =>
          google.maps.event.removeListener listener2
          @_triggerBoundsChanged()

    _getBounds: ->
      bounds = @map.getBounds()
      ne = bounds.getNorthEast()
      sw = bounds.getSouthWest()
      {
        n: ne.lat()
        s: sw.lat()
        e: ne.lng()
        w: sw.lng()
        z: @map.getZoom()
      }

    _triggerBoundsChanged: ->
      event = new rm.GoogleMapsEvent { bounds: @_getBounds() }
      rm.EventDispatcher.trigger rm.GoogleMapsEvent.BOUNDS_CHANGED, event

    _clearMap: ->
      for id, m of @markers
        m.setMap null
      @markers = {}

      for id, c of @clusters
        c.setMap null
      @clusters = {}

    _populateMarkers: (markers) ->
      for m in markers ? []
        @markers[m.id] = @createMarker m.lat, m.lng

    _populateClusters: (clusters) ->
      for c in clusters ? []
        @clusters[c.id] = new rm.Cluster @map, c

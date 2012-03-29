$ ->
  window.GoogleMapsApi = class GoogleMapsApi
    constructor: (mapOptions) ->
      @map = new google.maps.Map @canvas, mapOptions

    canvas: $('#map').get 0

$ ->
  module 'rm'

  rm.GoogleMapsApi = class GoogleMapsApi

    ###
      ID: Map container html element id 
    ###
    @ID = 'map'

    constructor: (mapOptions) ->
      canvas = document.getElementById GoogleMapsApi.ID
      @map = new google.maps.Map canvas, mapOptions

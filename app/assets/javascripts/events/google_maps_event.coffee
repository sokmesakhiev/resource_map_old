$ ->
  module 'rm'

  rm.GoogleMapsEvent = class GoogleMapsEvent
    constructor: (lat, lng) ->
      @lat = lat
      @lng = lng

  ### 
    GoogleMapsEvent Types 
  ###
  rm.GoogleMapsEvent.LOAD = 'GoogleMapsEvent:LOAD'

$ ->
  module 'rm'

  rm.GoogleMapsEvent = class GoogleMapsEvent
    constructor: (mapOptions) ->
      @mapOptions = mapOptions

  ### 
    GoogleMapsEvent Types 
  ###
  rm.GoogleMapsEvent.LOAD = 'GoogleMapsEvent:LOAD'

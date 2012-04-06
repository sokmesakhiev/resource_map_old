$ ->
  module 'rm'

  rm.GoogleMapsEvent = class GoogleMapsEvent
    constructor: (@data) ->

  ### 
    GoogleMapsEvent Types 
  ###
  rm.GoogleMapsEvent.LOAD = 'GoogleMapsEvent:LOAD'
  rm.GoogleMapsEvent.BOUNDS_CHANGED = 'GoogleMapsEvent:BOUNDS_CHANGED'

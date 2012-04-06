$ ->
  module 'rm'

  rm.ClusterMarker = class ClusterMarker
    constructor: (@options) ->
      @setMap @options?.map ? null
      @divs = {}
      @listeners = {}

  rm.ClusterMarker.prototype = new google.maps.OverlayView

  rm.ClusterMarker::onAdd = ->
    panes = @getPanes()
    panes.overlayImage.appendChild @_div 'cluster'
    panes.overlayImage.appendChild @_div 'cluster-count', @options.count
    panes.overlayShadow.appendChild @_div 'cluster-shadow'
    panes.overlayMouseTarget.appendChild @_div 'cluster-click'
    panes.overlayMouseTarget.appendChild @_div 'cluster-count-click'

    # FIXME: adjustZIndex is broken
    #@adjustZIndex()
    @setActive false

    @_addClickListener @_div 'cluster-click'
    @_addClickListener @_div 'cluster-count-click'

  rm.ClusterMarker::draw = ->
    pos = @getProjection().fromLatLngToDivPixel(@options.position)
    @_div('cluster').style.left = @_div('cluster-click').style.left = "#{pos.x - 13}px"
    @_div('cluster').style.top = @_div('cluster-click').style.top = "#{pos.y - 36}px"

    @_div('cluster-shadow').style.left = "#{pos.x - 7}px"
    @_div('cluster-shadow').style.top = "#{pos.y - 36}px"

    # If the count on the cluster is too big (more than 3 digits)
    # we move the div containing the count to the left
    @digits = Math.floor(2 * Math.log(@options.count / 10) / Math.log(10))
    @digits = 0 if @digits < 0
    @_div('cluster-count').style.left = @_div('cluster-count-click').style.left = "#{pos.x - 12 - @digits}px"
    @_div('cluster-count').style.top = @_div('cluster-count-click').style.top = "#{pos.y + 2}px"

  rm.ClusterMarker::onRemove = ->
    @_removeDiv c for c in ['cluster', 'cluster-shadow', 'cluster-count', 'cluster-click', 'cluster-count-click']

  rm.ClusterMarker::setActive = (draw = true) ->
    $(@_div 'cluster').removeClass('inactive')
    $(@_div 'cluster-shadow').removeClass('inactive')
    @draw() if draw

  rm.ClusterMarker::setInactive = (draw = true) ->
    $(@_div 'cluster').addClass('inactive')
    @draw() if draw

  # rm.Cluster.prototype.adjustZIndex = ->
  #   zIndex = window.model.zIndex(@position.lat())
  #   @div.style.zIndex = zIndex if @div
  #   @countDiv.style.zIndex = zIndex - 10 if @countDiv

  rm.ClusterMarker::_div = (className, text = '') ->
    unless @divs[className]
      @divs[className] = document.createElement 'DIV'
      @divs[className].className = className
      @divs[className].innerText = text.toString()

    @divs[className]

  rm.ClusterMarker::_removeDiv = (className) ->
    if div = @divs[className]
      @_removeClickListener className
      div.parentNode.removeChild div
      div = null

  # Instead of a listener for click we create two listeners for mousedown and mouseup:
  # If the user clicks a cluster and drags it, we want to drag the map but not zoom in
  rm.ClusterMarker::_addClickListener = (div) ->
    if @listeners[div.className]
      google.maps.event.removeListener l for l in @listeners[div.className]
    
    @listeners[div.className] = []
    @listeners[div.className].push google.maps.event.addDomListener div, 'mousedown', => @originalLatLng = @options.map.getCenter()
    @listeners[div.className].push google.maps.event.addDomListener div, 'mouseup', =>
      center = @options.map.getCenter()
      if !@originalLatLng || (@originalLatLng.lat() == center.lat() && @originalLatLng.lng() == center.lng())
        @options.map.panTo @options.position
        nextZoom = (if @maxZoom then @maxZoom else @options.map.getZoom()) + 1
        @options.map.setZoom nextZoom

  rm.ClusterMarker::_removeClickListener = (className) ->
    if @listeners[className]
      google.maps.event.removeListener l for l in @listeners[className]

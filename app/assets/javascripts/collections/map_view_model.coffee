$(-> if $('#collections-main').length > 0

  class window.MapViewModel
    @constructorMapViewModel: ->
      @showingMap = ko.observable(true)
      @sitesCount = ko.observable(0)
      @sitesCountText = ko.computed => if @sitesCount() == 1 then '1 site on map' else "#{@sitesCount()} sites on map"

      @reloadMapSitesAutomatically = true
      @clusters = {}
      @siteIds = {}
      @mapRequestNumber = 0
      @geocoder = new google.maps.Geocoder()

      @markerImageInactive = new google.maps.MarkerImage(
        "/assets/marker_inactive.png", new google.maps.Size(20, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34)
      )
      @markerImageInactiveShadow = new google.maps.MarkerImage(
        "/assets/marker_inactive.png", new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )
      @markerImageTarget = new google.maps.MarkerImage(
        "/assets/marker_target.png", new google.maps.Size(20, 34), new google.maps.Point(0, 0), new google.maps.Point(10, 34)
      )
      @markerImageTargetShadow = new google.maps.MarkerImage(
        "/assets/marker_target.png", new google.maps.Size(37, 34), new google.maps.Point(20, 0), new google.maps.Point(10, 34)
      )

      $.each @collections(), (idx) =>
        @collections()[idx].checked.subscribe (newValue) =>
          @reloadMapSites()

    @initMap: ->
      return true unless @showingMap()
      return false if @map

      center = if @currentCollection()?.position()
                 @currentCollection().position()
               else if @collections().length > 0 && @collections()[0].position()
                 @collections()[0].position()
               else
                 new google.maps.LatLng(10, 90)

      mapOptions =
        center: center
        zoom: 4
        mapTypeId: google.maps.MapTypeId.ROADMAP
        scaleControl: true
      @map = new google.maps.Map document.getElementById("map"), mapOptions

      listener = google.maps.event.addListener @map, 'bounds_changed', =>
        google.maps.event.removeListener listener
        @reloadMapSites()

      google.maps.event.addListener @map, 'dragend', => @reloadMapSites()
      google.maps.event.addListener @map, 'zoom_changed', =>
        listener2 = google.maps.event.addListener @map, 'bounds_changed', =>
          google.maps.event.removeListener listener2
          @reloadMapSites() if @reloadMapSitesAutomatically

      true

    @showMap: (callback) ->
      if @showingMap()
        if callback && typeof(callback) == 'function'
          callback()
        return

      @markers = {}
      @clusters = {}
      @showingMap(true)
      showMap = =>
        if $('#map').length == 0
          setTimeout(showMap, 10)
        else
          @initMap()
          if callback && typeof(callback) == 'function'
            callback()
      setTimeout(showMap, 10)
      setTimeout(window.adjustContainerSize 10)

    @reloadMapSites: (callback) ->
      bounds = @map.getBounds()

      # Wait until map is loaded
      unless bounds
        setTimeout(( => @reloadMapSites(callback)), 100)
        return

      ne = bounds.getNorthEast()
      sw = bounds.getSouthWest()
      collection_ids = if @currentCollection()
                         [@currentCollection().id()]
                       else
                          c.id for c in @collections() when c.checked()
      query =
        n: ne.lat()
        s: sw.lat()
        e: ne.lng()
        w: sw.lng()
        z: @map.getZoom()
        collection_ids: collection_ids
      query.exclude_id = @selectedSite().id() if @selectedSite()?.id()
      query.search = @lastSearch() if @lastSearch()

      filter.setQueryParams(query) for filter in @filters()

      @mapRequestNumber += 1
      currentMapRequestNumber = @mapRequestNumber

      getCallback = (data = {}) =>
        return unless currentMapRequestNumber == @mapRequestNumber

        if @showingMap()
          @drawSitesInMap data.sites
          @drawClustersInMap data.clusters
          @reloadMapSitesAutomatically = true
          @adjustZIndexes()
          @updateSitesCount()

        callback() if callback && typeof(callback) == 'function'

      if query.collection_ids.length == 0
        # Save a request to the server if there are no selected collections
        getCallback()
      else
        $.get "/sites/search.json", query, getCallback

    @drawSitesInMap: (sites = []) ->
      dataSiteIds = {}
      editingSiteId = if @editingSite()?.id() && (@editingSite().editingLocation() || @editingSite().inEditMode()) then @editingSite().id() else null
      selectedSiteId = @selectedSite()?.id()
      oldSelectedSiteId = @oldSelectedSite?.id() # Optimization to prevent flickering

      # Add markers if they are not already on the map
      for site in sites
        dataSiteIds[site.id] = site.id
        unless @markers[site.id]
          if site.id == oldSelectedSiteId
            @markers[site.id] = @oldSelectedSite.marker
            @deleteMarkerListener site.id
            @setMarkerIcon @markers[site.id], 'active'
            @oldSelectedSite.deleteMarker false
            delete @oldSelectedSite
          else
            markerOptions =
              map: @map
              position: new google.maps.LatLng(site.lat, site.lng)
              zIndex: @zIndex(site.lat)
              optimized: false

            # Show site in grey if editing a site (but not if it's the one being edited)
            if editingSiteId && editingSiteId != site.id
              markerOptions.icon = @markerImageInactive
              markerOptions.shadow = @markerImageInactiveShadow
            if (selectedSiteId && selectedSiteId == site.id)
              markerOptions.icon = @markerImageTarget
              markerOptions.shadow = @markerImageTargetShadow
            @markers[site.id] = new google.maps.Marker markerOptions
          localId = @markers[site.id].siteId = site.id
          do (localId) =>
            @markers[localId].listener = google.maps.event.addListener @markers[localId], 'click', (event) =>
              @setMarkerIcon @markers[localId], 'target'
              @editSiteFromMarker localId

      # Determine which markers need to be removed from the map
      toRemove = []
      for siteId, marker of @markers
        toRemove.push siteId unless dataSiteIds[siteId]

      # And remove them
      for siteId in toRemove
        @deleteMarker siteId

      if @oldSelectedSite
        @oldSelectedSite.deleteMarker() if @oldSelectedSite.id() != selectedSiteId
        delete @oldSelectedSite

    @drawClustersInMap: (clusters = []) ->
      dataClusterIds = {}

      # Add clusters if they are not already on the map
      for cluster in clusters
        dataClusterIds[cluster.id] = cluster.id
        currentCluster = @clusters[cluster.id]
        if currentCluster
          currentCluster.setData(cluster)
        else
          currentCluster = @createCluster(cluster)

      # Determine which clusters need to be removed from the map
      toRemove = []
      for clusterId, cluster of @clusters
        toRemove.push clusterId unless dataClusterIds[clusterId]

      # And remove them
      @deleteCluster clusterId for clusterId in toRemove

    @setAllMarkersInactive: ->
      editingSiteId = @editingSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if editingSiteId == siteId then 'target' else 'inactive')
      for clusterId, cluster of @clusters
        cluster.setInactive()

    @setAllMarkersActive: ->
      selectedSiteId = @selectedSite()?.id()?.toString()
      for siteId, marker of @markers
        @setMarkerIcon marker, (if selectedSiteId == siteId then 'target' else 'active')
      for clusterId, cluster of @clusters
        cluster.setActive()

    @setMarkerIcon: (marker, icon) ->
      switch icon
        when 'active'
          marker.setIcon null
          marker.setShadow null
        when 'inactive'
          marker.setIcon @markerImageInactive
          marker.setShadow @markerImageInactiveShadow
        when 'target'
          marker.setIcon @markerImageTarget
          marker.setShadow @markerImageTargetShadow

    @deleteMarker: (siteId, removeFromMap = true) ->
      return unless @markers[siteId]
      @markers[siteId].setMap null if removeFromMap
      @deleteMarkerListener siteId
      delete @markers[siteId]

    @deleteMarkerListener: (siteId) ->
      if @markers[siteId].listener
        google.maps.event.removeListener @markers[siteId].listener
        delete @markers[siteId].listener

    @createCluster: (cluster) ->
      @clusters[cluster.id] = new Cluster @map, cluster

    @deleteCluster: (id) ->
      @clusters[id].setMap null
      delete @clusters[id]

    @zIndex: (lat) ->
      bounds = @map.getBounds()
      north = bounds.getNorthEast().lat()
      south = bounds.getSouthWest().lat()
      total = north - south
      current = lat - south
      -Math.round(current * 100000 / total)

    @adjustZIndexes: ->
      for siteId, marker of @markers
        marker.setZIndex(@zIndex(marker.getPosition().lat()))
      for clusterId, cluster of @clusters
        cluster.adjustZIndex()

    @updateSitesCount: ->
      count = 0
      bounds = @map.getBounds()
      for siteId, marker of @markers
        count += 1 if bounds.contains marker.getPosition()
      for clusterId, cluster of @clusters
        count += cluster.count if bounds.contains cluster.position
      count += 1 if @selectedSite()
      @sitesCount count

    @showTable: ->
      delete @markers
      delete @clusters
      delete @map
      @selectedSite().deleteMarker() if @selectedSite()
      @exitSite() if @editingSite()
      @showingMap(false)
      @refreshTimeago()
      @makeFixedHeaderTable()
      setTimeout(window.adjustContainerSize 10)

    @makeFixedHeaderTable: ->
      unless @showingMap()
        oldScrollLeft = $('.tablescroll').scrollLeft()

        $('table.GralTable').fixedHeaderTable 'destroy'
        $('table.GralTable').fixedHeaderTable footer: false, cloneHeadToFoot: false, themeClass: 'GralTable'

        setTimeout((->
          $('.tablescroll').scrollLeft oldScrollLeft
          window.adjustContainerSize()
        ), 20)

)
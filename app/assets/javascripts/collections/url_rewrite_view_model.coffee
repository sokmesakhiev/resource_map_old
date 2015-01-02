onCollections ->

  class @UrlRewriteViewModel
    @rewriteUrl: ->
      query = {}

      # Append collection parameters (search, filters, hierarchy, etc.)
      @currentCollection().setQueryParams(query) if @currentCollection()
      

      # Append selected site or editing site, if any
      if @editingSite()
        query.editing_site = @editingSite().id()
        query.collection_id = @editingSite().collection.id
      else if @selectedSite()
        query.selected_site = @selectedSite().id()
        query.selected_collection = @selectedSite().collection.id
        query.collection_id = @selectedSite().collection.id
      else if @currentCollection()
        query.collection_id = @currentCollection().id

      # Append map center and zoom
      if @map
        center = @map.getCenter()
        if center
          query.lat = center.lat()
          query.lng = center.lng()
          query.z = @map.getZoom()

      # Append map/table view mode
      query._table = true unless @showingMap()
      
      # Append alert view
      query._alert = true if @showingAlert()

      # Append locale
      query.locale = @locale if @locale

      location = document.createElement 'a'
      location.href = window.location
      location.search = $.param query
      History.pushState null, null, location

      @reloadMapSites()


    @processURL: ->
      selectedSiteId = null
      selectedCollectionId = null
      editingSiteId = null
      showTable = false
      groupBy = null

      collectionId = $.url().param('collection_id')

      if collectionId and not @currentCollection()
        @enterCollection collectionId
        
      @queryParams = $.url().param()
      for key of @queryParams
        value = @queryParams[key]
        switch key
          when 'lat', 'lng', 'z', 'collection_id', 'locale'
            continue
          when 'search'
            @search(value)
          when 'updated_since'
            switch value
              when 'last_hour' then @filterByLastHour()
              when 'last_day' then @filterByLastDay()
              when 'last_week' then @filterByLastWeek()
              when 'last_month' then @filterByLastMonth()
          when 'selected_site'
            selectedSiteId = parseInt(value)
            @editSiteFromId(selectedSiteId, collectionId)
          when 'selected_collection'
            selectedCollectionId = parseInt(value)
          when 'editing_site'
            editingSiteId = parseInt(value)
            @editSiteFromId(editingSiteId, collectionId)
          when '_table'
            showTable = true
          when 'hierarchy_code'
            groupBy = value
          when 'sort'
            @sort(value)
          when 'sort_direction'
            @sortDirection(value == 'asc')
          else
            continue if not @currentCollection()
            @expandedRefineProperty(key)

            if value.length >= 2 && value[0] in ['>', '<', '~'] && value[1] == '='
              @expandedRefinePropertyOperator(value.substring(0, 2))
              @expandedRefinePropertyValue(value.substring(2))
            else if value[0] in ['=', '>', '<']
              @expandedRefinePropertyOperator(value[0])
              @expandedRefinePropertyValue(value.substring(1))
            else
              @expandedRefinePropertyValue(value)
            @filterByProperty()

      @ignorePerformSearchOrHierarchy = false
      @performSearchOrHierarchy()

      if showTable
        @showTable()
      else
        @initMap()

      @selectSiteFromId(selectedSiteId, selectedCollectionId) if selectedSiteId
      @editSiteFromMarker(editingSiteId, collectionId) if editingSiteId
      @groupBy(@currentCollection().findFieldByEsCode(groupBy)) if groupBy && @currentCollection()

      @processingURL = false
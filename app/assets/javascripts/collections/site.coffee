#= require module
#= require collections/locatable

onCollections ->

  class @Site extends Module
    @include Locatable

    constructor: (collection, data) ->
      @constructorLocatable(data)
      @collection = collection
      @selected = ko.observable()
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @layers = ko.observableArray()
      @fields = ko.observableArray()
      @fieldsInitialized = false
      @icon = data?.icon ? 'default'
      @color = data?.color
      @idWithPrefix = ko.observable data?.id_with_prefix
      @properties = ko.observable data?.properties
      @updatedAt = ko.observable(data?.updated_at)
      @updatedAtTimeago = ko.computed => if @updatedAt() then $.timeago(@updatedAt()) else ''
      @editingName = ko.observable(false)
      @editingLocation = ko.observable(false)
      @photos = {}
      @photosToRemove = []
      @alert = ko.observable data?.alert
      @locationText = ko.computed
        read: =>
          if @hasLocation()
            (Math.round(@lat() * 100000000000) / 100000000000) + ', ' + (Math.round(@lng() * 100000000000) / 100000000000)
          else
            ''
        write: (value) => @locationTextTemp = value
        owner: @
      @locationTextTemp = @locationText()
      @valid = ko.computed => @hasName() and @hasInputMendatoryProperties()
      @highlightedName = ko.computed => window.model.highlightSearch(@name())
      @inEditMode = ko.observable(false)

    hasLocation: => @position() != null

    hasName: => $.trim(@name()).length > 0

    hasInputMendatoryProperties: =>
      for field in @fields()
        if field.is_mandatory and !field.value()
          return false
      return true

    propertyValue: (field) =>
      value = @properties()[field.esCode]
      field.valueUIFor(value)

    highlightedPropertyValue: (field) =>
      window.model.highlightSearch(@propertyValue(field))

    fetchLocation: =>
      $.get "/collections/#{@collection.id}/sites/#{@id()}.json", {}, (data) =>
        @position(data)
        @updatedAt(data.updated_at)
      @collection.fetchLocation()

    findFieldByEsCode: (esCode) => (field for field in @fields() when field.esCode == esCode)[0]

    updateProperty: (esCode, value) =>
      field = @findFieldByEsCode(esCode)
      if field.showInGroupBy && window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, [{field: field, oldValue: @properties()[esCode], newValue: value}])

      @properties()[esCode] = value
      $.ajax({
        type: "POST",
        url: "/sites/#{@id()}/update_property.json",
        data: {es_code: esCode, value: value},
        success: ((data) =>
          field.errorMessage("")
          @propagateUpdatedAt(data.updated_at)
          window.model.updateSitesInfo()),
        global: false
      })
      .fail((data) =>
        try
          responseMessage = JSON.parse(data.responseText)
          if data.status == 422 && responseMessage && responseMessage.error_message
            field.errorMessage(responseMessage.error_message)
          else
            $.handleAjaxError(data)
        catch error
          $.handleAjaxError(data))

    fillPhotos: (collection) =>
      @photo = {}
      for field in @fields()
        if field.kind == 'photo'
          if !!field.value() and !!field.photo
            @photos[field.value()] = field.photo
          if field.originalValue and !field.value()
            @photosToRemove.push(field.originalValue)

    copyPropertiesFromCollection: (collection) =>
      oldProperties = @properties()

      hierarchyChanges = []

      @properties({})
      for field in @fields()
        if field.kind == 'hierarchy' && @id()
          hierarchyChanges.push({field: field, oldValue: oldProperties[field.esCode], newValue: field.value()})

        if field.value()
          value = field.value()

          @properties()[field.esCode] = value
        else
          delete @properties()[field.esCode]

      if window.model.currentCollection()
        window.model.currentCollection().performHierarchyChanges(@, hierarchyChanges)

    copyPropertiesToCollection: (collection) =>
      collection.fetchFields =>
        if @fields().length == 0
          collection.clearFieldValues()
          for field in collection.fields()
            @fields.push(field)

          for layer in collection.layers()
            @layers.push(layer)
          @copyPropertiesToFields()

    update_site: (json, callback, callbackError) =>
      data = {site: JSON.stringify json}
      if JSON.stringify(@photos) != "{}"
        data["fileUpload"] = @photos

      if @photosToRemove.length > 0
        data["photosToRemove"] = @photosToRemove

      $.ajax({
          type: "PUT",
          url: "/collections/#{@collection.id}/sites/#{@id()}.json",
          data: data,
          success: ((data) =>
            for field in @fields()
              field.errorMessage("")
            @propagateUpdatedAt(data.updated_at)
            callback(data) if callback && typeof(callback) == 'function' )
          error: ((request, status, error) =>
            callbackError())
          global: false
        }).fail((data) =>
          try
            propertyErrors = JSON.parse(data.responseText)["properties"]
            for field in @fields()
              field.errorMessage("")
            if data.status == 422 && propertyErrors
              for prop in propertyErrors
                for es_code, value of prop
                  f = this.findFieldByEsCode(es_code)
                  f.errorMessage(value)
            else
              $.handleAjaxError(data)
          catch error
            $.handleAjaxError(data))


    create_site: (json, callback, callbackError) =>
      data = {site: JSON.stringify json}
      if JSON.stringify(@photos) != "{}"
        data["fileUpload"] = @photos
      $.ajax({
          type: "POST",
          url: "/collections/#{@collection.id}/sites",
          data: data,
          success: ((data) =>
            @photos = {}
            for field in @fields()
              field.errorMessage("")
            @propagateUpdatedAt(data.updated_at)
            @id(data.id)
            @idWithPrefix(data.id_with_prefix)
            $.status.showNotice window.t('javascripts.collections.index.site_created', {name: @name()}), 2000
            callback(data) if callback && typeof(callback) == 'function' )
          error: ((request, status, error) =>
            callbackError())
          global: false
        }).fail((data) =>
          try
            propertyErrors = JSON.parse(data.responseText)["properties"]
            for field in @fields()
              field.errorMessage("")
            if data.status == 422 && propertyErrors
              for prop in propertyErrors
                for es_code, value of prop
                  f = @collection.findFieldByEsCode(es_code)
                  f.errorMessage(value)
            else
              $.handleAjaxError(data)
          catch error
            $.handleAjaxError(data))
  

    propagateUpdatedAt: (value) =>
      @updatedAt(value)
      @collection.propagateUpdatedAt(value)

    editName: =>
      if !@collection.currentSnapshot
        @originalName = @name()
        @editingName(true)

    nameKeyPress: (site, event) =>
      switch event.keyCode
        when 13 then @saveName()
        when 27 then @exitName()
        else true

    saveName: =>
      if @hasName()
        @update_site name: @name()
        @collection.reloadSites()
        @editingName(false)
      else
        @exitName()

    exitName: =>
      @name(@originalName)
      @editingName(false)
      delete @originalName

    editLocation: =>
      if !@collection.currentSnapshot
        @editingLocation(true)
        @startEditLocationInMap()

    startEditLocationInMap: =>
      @originalLocation = @position()

      if @marker
        @setupMarkerListener()
      else
        @createMarker()
        @alertMarker.setMap null if @alertMarker
      @marker.setDraggable(true)
      window.model.setAllMarkersInactive()
      @panToPosition()

    endEditLocationInMap: (position) =>
      @editingLocation(false)
      @position(position)
      if @alertMarker
        @marker.setMap null
        delete @marker
        @alertMarker.setMap window.model.map
        @alertMarker.setData( id: @id(), collection_id: @collection.id, lat: @lat(), lng: @lng(), color: @color, icon: @icon, target: true)
      else
        @marker.setPosition(@position()) if position
        @marker.setDraggable false
        @deleteMarker() if !@position()

      window.model.setAllMarkersActive()
      @panToPosition()

    locationKeyPress: (site, event) =>
      switch event.keyCode
        when 13 then @saveLocation()
        when 27 then @exitLocation()
        else true

    saveLocation: =>
      window.model.setAllMarkersActive()

      save = =>
        @update_site lat: @lat(), lng: @lng(), (data) =>
          @collection.fetchLocation()
          @endEditLocationInMap(@extractPosition data)
          window.model.updateSitesInfo()

      @parseLocation
        success: (position) => @position(position); save()
        failure: (position) => @position(position); @endEditLocationInMap(position)

    extractPosition: (from) ->
      if from.lat || from.lng then { lat: from.lat, lng: from.lng } else null

    newLocationKeyPress: (site, event) =>
      switch event.keyCode
        when 13
          if $.trim(@locationTextTemp).length == 0
            @position(null)
            return true
          else
            @moveLocation()
            false
        else
          true

    moveLocation: =>
      callback = (position) =>
        @position(position)
        if position then @marker.setPosition(position)
        @panToPosition()
      @parseLocation success: callback, failure: callback

    tryGeolocateName: =>
      return if @inEditMode() || @nameBeforeGeolocateName == @name()

      @nameBeforeGeolocateName = @name()
      @parseLocation text: @fullName(), success: (position) =>
        @position(position)
        @marker.setPosition(position)
        @panToPosition()

    fullName: => "#{@collection.name}, #{@name()}"

    parseLocation: (options) =>
      text = options.text || @locationTextTemp
      # Is text of the form 'num1.num1,num2.num2' after trimming whitespace?
      # If so, give me num1.num1 and num2.num2
      if match = text.match(/^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$/)
        options.success(new google.maps.LatLng(parseFloat(match[1]), parseFloat(match[2])))
      else
        if text == ''
          options.success(null)
        else
          window.model.geocoder.geocode { 'address': text}, (results, status) =>
            if results.length > 0
              options.success(results[0].geometry.location)
            else
              options.failure(@originalLocation) if options.failure?

    exitLocation: =>
      @endEditLocationInMap(@originalLocation)
      delete @originalLocation

    startEditMode: =>
      # Keep the original values, in case the user cancels
      @originalName = @name()
      @originalPosition = @position()
      for field in @fields()
        field.editing(false)
        field.originalValue = field.value()

      @inEditMode(true)
      @startEditLocationInMap()
      window.model.initDatePicker()
      window.model.initAutocomplete()

    exitEditMode: (saved) =>
      @inEditMode(false)

      @endEditLocationInMap(if saved then @position() else @originalLocation)

      # Restore original name and position if not saved
      unless saved
        @name(@originalName)
        @position(@originalPosition)
        delete @originalName
        delete @originalPosition

      # Expand fields, clear filters (select_many),
      # and restore original field values if not saved
      for field in @fields()
        field.expanded(false)
        field.filter('')

        unless saved
          field.value(field.originalValue)
          delete field.originalValue

    createMarker: (drop = false) =>
      @deleteMarker()

      position =  @position() || window.model.map.getCenter()

      draggable = @editingLocation() || !@id()
      @marker = new google.maps.Marker
        map: window.model.map
        position: position
        animation: if drop || !@id() || !@position() then google.maps.Animation.DROP else null
        draggable: draggable
        icon: window.model.markerImage 'resmap_' + @icon + '_target.png'
        zIndex: 2000000
      @marker.name = @name()
      @setupMarkerListener()
      window.model.setAllMarkersInactive() if draggable

    createAlert: () =>
      @deleteAlertMarker()
      @alertMarker = new Alert window.model.map, {id: @id(), collection_id: @collection.id, lat: @lat(), lng: @lng(), color: @color, icon: @icon, target: true}

    deleteMarker: (removeFromMap = true) =>
      return unless @marker
      @marker.setMap null if removeFromMap
      delete @marker
      @deleteMarkerListener() if removeFromMap

    deleteAlertMarker: (removeFromMap = true) =>
      return unless @alertMarker
      @alertMarker.setMap null if removeFromMap
      delete @alertMarker

    deleteMarkerListener: =>
      return unless @markerListener
      google.maps.event.removeListener @markerListener
      delete @markerListener

    setupMarkerListener: =>
      @markerListener = google.maps.event.addListener @marker, 'position_changed', =>
        @position(@marker.getPosition())
        @locationText("#{@marker.getPosition().lat()}, #{@marker.getPosition().lng()}")

    setupAlerMarkerListener: =>
      @alertMarkerListener = google.maps.event.addListener @alertMarker, 'position_changed', =>
        @position(@marker.getPosition())

    toJSON: =>
      json =
        id: @id()
        name: @name()
      json.lat = @lat() if @lat()
      json.lng = @lng() if @lng()
      json.properties = @properties() if @properties()
      json

    fetchFields: (callback) =>
      if @fieldsInitialized
        callback() if callback && typeof(callback) == 'function'
        return

      @fieldsInitialized = true
      $.get "/collections/#{@collection.id}/sites/#{@id()}/visible_layers_for", {}, (data) =>
        @layers($.map(data, (x) => new Layer(x)))

        fields = []
        @fields(fields)
        for layer in @layers()
          for field in layer.fields
            fields.push(field)
        @fields(fields)

        @copyPropertiesToFields()
        $('a#previewimg').fancybox()
        callback() if callback && typeof(callback) == 'function'

    copyPropertiesToFields: =>
      if @properties()
        for field in @fields()
          value = @properties()[field.esCode]
          field.setValueFromSite(value)

    clearFieldValues: =>
      field.value(null) for field in @fields()

    # Ary: I have no idea why, but without this here toJSON() doesn't work
    # in Firefox. It seems a problem with the bindings caused by the fat arrow
    # (=>), but I couldn't figure it out. This "solves" it for now.
    dummy: =>

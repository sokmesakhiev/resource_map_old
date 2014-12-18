#= require collections/collection_base

onCollections ->

  class @Collection extends CollectionBase
    constructor: (data) ->
      super(data)
      @minLat = data?.min_lat
      @maxLat = data?.max_lat
      @minLng = data?.min_lng
      @maxLng = data?.max_lng
      @layers = ko.observableArray()
      @fields = ko.observableArray()
      @title = ko.observable()
      @thresholds = ko.observableArray()
      @refineFields = ko.observableArray()
      @checked = ko.observable if window.currentUserIsGuest then false else true
      @fieldsInitialized = false
      # @loadSites()
      @groupByOptions = ko.computed =>
        defaultOptions = []
        if window.model
          defaultOptions =[window.model.defaultGroupBy]
        defaultOptions.concat(@fields().filter((f) -> f.showInGroupBy))
      
    isSearch: => false

    sitesUrl: -> "/collections/#{@id}/sites.json"

    fetchLocation: => $.get "/collections/#{@id}.json", {}, (data) =>
      @minLat = data.min_lat
      @maxLat = data.max_lat
      @minLng = data.min_lng
      @maxLng = data.max_lng
      @position(data)
      @updatedAt(data.updated_at)

    panToPosition: =>
      if @minLat && @maxLat && @minLng && @maxLng
        window.model.map.fitBounds new google.maps.LatLngBounds(
          new google.maps.LatLng(@minLat, @minLng),
          new google.maps.LatLng(@maxLat, @maxLng)
        )
      else if @position()
        window.model.map.panTo @position()

    # loadSites: =>
    #   $.get @sitesUrl(), (data) =>
    #     for site in data
    #       @addSite @createSite(site)



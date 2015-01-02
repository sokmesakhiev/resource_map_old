#= require collections/collection_base

onCollections ->

  class @CollectionDecorator extends CollectionBase
    constructor: (collection) ->
      # These three are because we are not calling super
      @constructorLocatable(lat: collection.lat(), lng: collection.lng())
      @constructorSitesContainer()
      @constructorSitesMembership()
      @loadCurrentSnapshotMessage()

      @loadAllSites()

      @collection = collection
      @currentSnapshot = collection.currentSnapshot

      @id = collection.id
      @name = collection.name
      @layers = collection.layers
      @fields = collection.fields
      @fieldsInitialized = collection.fieldsInitialized
      @refineFields = collection.fields
      @groupByOptions = collection.groupByOptions
      @sitesPermission = collection.sitesPermission
      @thresholds = collection.thresholds
      @showLegend = collection.showLegend
      @allSites(collection.allSites())


    createSite: (site) => new Site(@collection, site)

    # These two methods are needed to be forwarded when editing sites inside a search
    updatedAt: (value) => @collection.updatedAt(value)
    fetchLocation: => @collection.fetchLocation()

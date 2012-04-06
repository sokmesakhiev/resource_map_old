#= require helpers/collections_view_helper
#= require models/collection

$ ->
  module 'rm'

  rm.CollectionsViewModel = class CollectionsViewModel

    @Urls =
      NEW   : '/collections/new'

    constructor: () ->
      @helper = rm.CollectionsViewHelper
      @collections = ko.observableArray()
      @showingMap = ko.observable true
      @sites = ko.observableArray()

    createCollection: ->
      rm.Utils.redirect CollectionsViewModel.Urls.NEW

    showTable: ->
      @_showingMap false
      @helper.refreshTimeago()
      @helper.makeFixedHeaderTable()

    showMap: ->
      @_showingMap true
      @_dispatchGoogleMapsLoad()

    _showingMap: (newValue) ->
      @showingMap newValue unless @showingMap() == newValue
      @helper.adjustContainerSize()

    _dispatchGoogleMapsLoad: ->
      event = new rm.GoogleMapsEvent { lat: @collections()[0]?.lat(), lng: @collections()[0]?.lng() }
      rm.EventDispatcher.trigger rm.GoogleMapsEvent.LOAD, event

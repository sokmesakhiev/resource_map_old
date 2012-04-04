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

    createCollection: ->
      rm.Utils.redirect CollectionsViewModel.Urls.NEW

    showTable: ->
      @_showingMap false
      @helper.refreshTimeago()

    showMap: ->
      @_showingMap true
      @_dispatchGoogleMapsLoad()

    _showingMap: (newValue) ->
      @showingMap newValue unless @showingMap() == newValue
      @helper.adjustContainerSize()

    _dispatchGoogleMapsLoad: ->
      event = new rm.GoogleMapsEvent @collections()[0]?.lat(), @collections()[0]?.lng()
      rm.EventDispatcher.trigger rm.GoogleMapsEvent.LOAD, event

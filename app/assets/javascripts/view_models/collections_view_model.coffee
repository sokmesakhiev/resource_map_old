$ ->
  module 'rm'

  rm.CollectionsViewModel = class CollectionsViewModel

    @Urls =
      NEW   : '/collections/new'

    constructor: () ->
      @collections = ko.observableArray()
      @showingMap = ko.observable true

    createCollection: ->
      rm.Utils.redirect CollectionsViewModel.Urls.NEW

    showTable: ->
      @showingMap false

    showMap: ->
      @showingMap true

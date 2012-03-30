$ ->
  module 'rm'

  rm.CollectionsViewModel = class CollectionsViewModel

    @URLS =
      new: '/collections/new'

    constructor: () ->
      @collections = ko.observableArray()

    createCollection: ->
      rm.Utils.redirect CollectionsViewModel.URLS.new

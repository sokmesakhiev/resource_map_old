$ ->
  module 'rm'

  rm.CollectionsViewModel = class CollectionsViewModel
    constructor: () ->
      @collections = ko.observableArray()

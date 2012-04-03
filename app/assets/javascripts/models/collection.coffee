$ ->
  module 'rm'

  rm.Collection = class Collection
    constructor: (data) ->
      @name = ko.observable data?.name
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng

    showMe: ->
      alert @name()

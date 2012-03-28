$ ->
  module 'rm'

  rm.Collection = class Collection
    constructor: (data) ->
      @name = ko.observable data?.name

    showMe: ->
      alert @name()

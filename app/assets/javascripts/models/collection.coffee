$ ->
  module 'rm'

  rm.Collection = class Collection
    constructor: (data) ->
      @name = ko.observable data?.name
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @updatedAt = ko.observable data.updated_at
      @updatedAtTimeago = ko.computed =>
        if @updatedAt()
          $.timeago(@updatedAt())
        else ''

    showMe: ->
      alert @name()

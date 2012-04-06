$ ->
  module 'rm'

  rm.Collection = class Collection
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @lat = ko.observable data?.lat
      @lng = ko.observable data?.lng
      @checked = ko.observable true
      @updatedAt = ko.observable data?.updated_at
      @updatedAtTimeago = ko.computed =>
        if @updatedAt()
          $.timeago(@updatedAt())
        else ''

    showMe: ->
      alert @name()

module 'rm'

rm.Collections = class Collections
  constructor: (collections) ->
    @collections = ko.observable collections

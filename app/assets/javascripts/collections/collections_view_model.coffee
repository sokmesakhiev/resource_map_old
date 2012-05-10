$(-> if $('#collections-main').length > 0

  class window.CollectionsViewModel
    @constructorCollectionsViewModel: (collections) ->
      @collections = ko.observableArray $.map(collections, (x) -> new Collection(x))
      @currentCollection = ko.observable()

    @findCollectionById: (id) -> (x for x in @collections() when x.id() == id)[0]

    @goToRoot: -> location.hash = '/'

    @enterCollection: (collection) -> location.hash = "#{collection.id()}"

    @editCollection: (collection) -> window.location = "/collections/#{collection.id()}"

    @createCollection: -> window.location = "/collections/new"
)
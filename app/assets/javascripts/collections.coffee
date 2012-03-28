$ ->
  collectionViewModel =
    collections: ko.observableArray([])
    index: ->
      $.get "/collections.json", (data) ->
        collectionViewModel.collections data

  console.log('hello');
  ko.applyBindings collectionViewModel
  collectionViewModel.index()

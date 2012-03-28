$ ->
  class CollectionViewModel
    constructor: ->
      @name = ko.observable("Clinic")

  ko.applyBindings(new CollectionViewModel);
  alert("me")

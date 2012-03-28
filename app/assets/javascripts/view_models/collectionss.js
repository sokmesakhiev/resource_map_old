$(function(){
  function collections_viewmodel(){
    self = this;
    self.collections = ko.observableArray([
      new collection("Cambodia Health Center"),
      new collection("Gas Station")]);

  }
  ko.applyBindings(new collections_viewmodel());
});

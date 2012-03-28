function collection(name){
  this.name = ko.observable(name);
  this.showMe = function(){
    alert(name);
  }
}

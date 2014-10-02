//= require mobile/events
//= require mobile/field
//= require mobile/option
//= require mobile/field_logic
//= require mobile/sub_hierarchy

function Collection (collection) {
  this.id = collection != null ? collection.id : void 0;
  this.name = collection != null ? collection.name : void 0;
  this.layers = collection != null ? collection.layers : void 0;
  this.fields = [];
};

Collection.prototype.pushingPendingSites = function(){
  pendingSites = JSON.parse(window.localStorage.getItem("offlineSites"));
  if(pendingSites != null){
    for(var i=0; i< pendingSites.length; i++){
      data = pendingSites[i]["formData"];
      if(data["id"]){
        Collection.prototype.ajaxUpdateOfflineSite(pendingSites[i]["collectionId"], data);
      }
      else{
        Collection.prototype.ajaxCreateOfflineSite(pendingSites[i]["collectionId"], data);
      }
    }
    window.localStorage.setItem("offlineSites", JSON.stringify([]));
  }
  // Collection.prototype.goHome();

}

Collection.prototype.fetchFields = function() {
  var fields = [];
  var layers = this.layers();
  for (var i = 0; i < layers.length; i++) {
    layer = layers[i];
    fields = layer.fields();
    for (j = 0; j < fields.length; j++) {
      field = fields[j];
      field.value(null);
      fields.push(field);
    }
  }
  return this.fields(fields);
};

Collection.prototype.createSite = function(id){
  Collection.prototype.showFormAddSite(Collection.getSchemaByCollectionId(id));
}

Collection.getSchemaByCollectionId = function(id){
  for(var i=0; i< window.collectionSchema.length; i++){
    if(window.collectionSchema[i]["id"] == id){
      return window.collectionSchema[i];
    }
  }
}

Collection.prototype.showFormAddSite = function(schema){
  Collection.hidePages();
  Collection.clearFormData();
  $("#mobile-sites-main").show();
  fieldHtml = Collection.prototype.addLayerForm(schema);
  $("#title").html(schema["name"]);
  $("#fields").html(fieldHtml);
  Collection.prototype.applyBrowserLocation();
  Collection.prototype.handleFieldUI(schema);
}

Collection.prototype.saveSite = function(){  
  var collectionId = window.currentCollectionId;
  if(Collection.prototype.validateData(collectionId)){    
    if(window.navigator.onLine){
      if(window.currentSiteId){
        var formData = new FormData($('form')[0]);
        Collection.prototype.ajaxUpdateSite(collectionId, window.currentSiteId, formData);
      }
      else{
        var formData = new FormData($('form')[0]);
        Collection.prototype.ajaxCreateSite(collectionId, formData);
      }
    }
    else{
      var offlineData = Collection.prototype.getFormValue();
      if(window.currentSiteId){
        offlineData["id"] = window.currentSiteId;
      }
      Collection.prototype.storeOfflineData(collectionId, offlineData);
    }
  }
}

Collection.prototype.storeOfflineData = function(collectionId, formData){
  pendingSites = JSON.parse(window.localStorage.getItem("offlineSites"));
  if(pendingSites != null && pendingSites.length > 0){
    pendingSites.push({"collectionId" : collectionId, "formData" : formData});
  }
  else{
    pendingSites = [{"collectionId" : collectionId, "formData" : formData}];
  }
  try {
    window.localStorage.setItem("offlineSites", JSON.stringify(pendingSites));
    Collection.prototype.goHome();
    Collection.prototype.showErrorMessage("Offline site saved locally.");
  }catch (e) {
    Collection.prototype.showErrorMessage("Unable to save record because your data is too big.");
  }
  
}

Collection.prototype.ajaxCreateSite = function(collectionId, formData){
  $.mobile.saving('show');
  $.ajax({
      url: '/mobile/collections/' + collectionId + '/sites',  //Server script to process data
      type: 'POST',
      success: function(){
        Collection.prototype.showListSites(collectionId);
        Collection.prototype.showErrorMessage("Successfully saved.");
      },
      error: function(data){
        var properties = JSON.parse(data.responseText);
        var error = "";
        for(var i=0;i<properties.length; i++){
          error = error + properties[i] + " .";
        }
        Collection.prototype.showErrorMessage("Save new site failed!" + error);
      },
      complete: function() {
        $.mobile.saving('hide');
      },
      data: formData,
      contentType: false,
      processData: false,
      cache: false
  });
}

Collection.prototype.ajaxUpdateSite = function(collectionId, siteId, formData){
  $.mobile.saving('show');
  $.ajax({
      url: '/mobile/collections/' + collectionId + '/sites/' + siteId + '.json',  //Server script to process data
      type: 'PUT',
      success: function(){
        Collection.prototype.showListSites(collectionId);
        Collection.prototype.showErrorMessage("Successfully updated.");
      },
      error: function(data){
        var properties = JSON.parse(data.responseText);
        var error = "";
        for(var i=0;i<properties.length; i++){
          error = error + properties[i] + " .";
        }
        Collection.prototype.showErrorMessage("Update site failed!" + error);
      },
      complete: function() {
        $.mobile.saving('hide');
      },
      data: formData,
      contentType: false,
      processData: false,
      cache: false
  });
}

Collection.prototype.ajaxCreateOfflineSite = function(collectionId, formData){
  $.ajax({
      url: '/mobile/collections/' + collectionId + '/create_offline_site',  //Server script to process data
      type: 'POST',
      success: function(){
        Collection.prototype.showErrorMessage("Locally saved sites synced successfully.");
      },
      error: function(data){
        Collection.prototype.showErrorMessage("Locally saved sites synced failed.");
      },
      data: formData,
      cache: false
  });
}

Collection.prototype.ajaxUpdateOfflineSite = function(collectionId, formData){
  $.ajax({
      url: '/mobile/collections/' + collectionId + '/sites/' + formData["id"]+ '/update_offline_site',  //Server script to process data
      type: 'PUT',
      success: function(){
        Collection.prototype.showErrorMessage("Locally update sites synced successfully.");
      },
      error: function(data){
        Collection.prototype.showErrorMessage("Locally update sites synced failed.");
      },
      data: formData,
      cache: false
  });
}

Collection.prototype.validateData = function(collectionId){
  if($("#name").val().trim() == ""){
    Collection.prototype.showErrorMessage("Name can not be empty.");
    return false;
  }
  if($("#lat").val().trim() == ""){
    Collection.prototype.showErrorMessage("Location's latitude can not be empty.");
    return false;
  }
  if($("#lng").val().trim() == ""){
    Collection.prototype.showErrorMessage("Location's longitude can not be empty.");
    return false;
  }

  for(var k=0; k< window.collectionSchema.length; k++){
    if(window.collectionSchema[k]["id"] == collectionId){
      schema = window.collectionSchema[k];
      for(i=0; i<schema["layers"].length;i++){
        for(j=0; j<schema["layers"][i]["fields"].length; j++){
          var field = schema["layers"][i]["fields"][j];
          state = true;
          switch(field["kind"])
          {
            case "text":
              state = Collection.valiateMandatoryText(field);
              break;
            case "numeric":
              value = $("#" + field["code"]).val();
              range = field["config"]["range"];
              if(Collection.prototype.validateNumeric(value) == false){
                Collection.prototype.showErrorMessage(field["name"] + " is not valid numeric value.");
                return false;
              }else{
                if(range){                  
                  if(Collection.prototype.validateRange(value, range) == false){
                    Collection.prototype.showErrorMessage("Invalid number range");
                    Collection.setFieldStyleFailed(field["code"]);
                    return false;
                  }
                }
              }
              state =  Collection.valiateMandatoryText(field);
              break;
            case "date":
              state =  Collection.valiateMandatoryText(field);
              break;
            case "yes_no":
              break;
            case "select_one":
              state =  Collection.valiateMandatorySelectOne(field);
              break;
            case "select_many":
              state =  Collection.valiateMandatorySelectMany(field);
              break;
            case "phone number":
              state =  Collection.valiateMandatoryText(field);
              break;
            case "email":
              value = $("#" + field["code"]).val();
              if(Collection.prototype.validateEmail(value) == false){
                Collection.prototype.showErrorMessage(field["name"] + " is not a valid email value.");
                return false;
              }
              state =  Collection.valiateMandatoryText(field);
              break;
            case "photo":
              state =  Collection.valiateMandatoryPhoto(field);
              break;
          }
          if(!state){
            Collection.prototype.showErrorMessage(field["name"] + " is mandatory.");
            Collection.setFieldStyleFailed(field["code"]);
            return false
          }
          else{
            Collection.setFieldStyleSuccess(field["code"]);
          }
        }
      }
    }
  }

  return true;
}

Collection.setFocusOnField = function(fieldId){
  els = $(".field_" + fieldId);
  selected_options = []
  for(var i=0; i<els.length; i++){
    if(els[i].checked)
      selected_options.push(els[i].checked);
  }
  id = Collection.findNextFieldId(fieldId, selected_options);
  if(id){
    fieldFocus = Collection.prototype.findFieldById(id); 
    Collection.prototype.setFieldFocusStyleByKind(fieldFocus);
  }
}

Collection.findNextFieldId = function(fieldId, options){
  layers = Collection.getSchemaByCollectionId(window.currentCollectionId).layers;
  field = null;
  for(var i=0; i<layers.length; i++){
    fields = layers[i].fields
    for(var j=0; j<fields.length; j++){
      if(fields[j].id == fieldId);
        field = fields[j];
    }
  }
  if(field.is_enable_field_logic){
    field_logics = field.config["field_logics"]
    for(var j=0; j<field_logics.length; j++){
      if(field_logics[j].condition_type == "all"){
        valid = Collection.checkAllConditionFieldLogic(field_logics[j]["selected_options"], options);
        if(valid){
          return field_logics[j]["field_id"];
        }
        return null;
      }
      else{
        valid = Collection.checkAnyConditionFieldLogic(field_logics[j]["selected_options"], options);
        if(valid){
          return field_logics[j]["field_id"];
        }
        return null;
      }
    }
  }
  else{
    return null;
  }
}

Collection.checkAllConditionFieldLogic = function(selectedOptions, options){
  for(op in selectedOptions){
    meet_condition = false
    for(var j=0; j<options.length; j++){
      if(selectedOptions[op]["value"] == options[j]){
        meet_condition = true;
      }
    }
    if(meet_condition == false){
      return false
    }
  }
  return false;
}

Collection.checkAnyConditionFieldLogic = function(selectedOptions, options){
  meet_condition = false
  for(op in selectedOptions){
    for(var j=0; j<options.length; j++){
      if(selectedOptions[op]["value"] == options[j]){
        meet_condition = true;
      }
    }
  }
  return meet_condition;
}

Collection.setFieldStyleSuccess = function(id){
  $("#div_wrapper_" + id).removeClass("invalid_field")
}

Collection.setFieldStyleFailed = function(id){
  $("#div_wrapper_" + id).addClass("invalid_field")
  $("#" + id).focus()
}

Collection.valiateMandatoryPhoto = function(field){
  value = $("#" + field["code"]).val();
  if(field["is_mandatory"] == true && value == ""){
    return false
  }
  return true
}

Collection.valiateMandatorySelectMany = function(field){
  value = $("input[name='properties[" + field["id"] + "][]']:checked").length;
  if(field["is_mandatory"] == true && value == 0){
    return false
  }
  return true
}

Collection.valiateMandatorySelectOne = function(field){
  value = $("#" + field["code"]).val();
  if(field["is_mandatory"] == true && value == 0 ){
    return false
  }
  return true
}

Collection.valiateMandatoryText = function(field){
  value = $("#" + field["code"]).val();
  if(field["is_mandatory"] == true && value == ""){
    return false
  }
  return true
}

Collection.prototype.validateEmail = function(email) {
  if(email == ""){
    return true;
  }
  else{
    var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(email);
  }
}

Collection.prototype.validateNumeric = function(number) {
  if(number == ""){
    return true;
  }
  else{
    var RE = /^-{0,1}\d*\.{0,1}\d+$/;
    return (RE.test(number));
  }
}

Collection.prototype.validateRange = function(number, range){
  if(range["minimum"] && range["maximum"]){
    if(parseInt(number) >= parseInt(range["minimum"]) && parseInt(number) <= parseInt(range["maximum"]))
      return true;
    else
      return false;
  }
  else{
    if(range["maximum"]){
      if(parseInt(number) <= parseInt(range["maximum"]))
        return true;
      else
        return false;      
    }
    if(range["minimum"]){
      if(parseInt(value) >= parseInt(range["minimum"]))
        return true;
      else
        return false;      
    }
  }
  return true;
}

Collection.prototype.showErrorMessage = function(text){
  $.mobile.showPageLoadingMsg( $.mobile.pageLoadErrorMessageTheme, text, true );
  // hide after delay
  setTimeout( $.mobile.hidePageLoadingMsg, 2000 );
}

Collection.prototype.progressHandlingFunction =function(e){
  if(e.lengthComputable){
    $('progress').attr({value:e.loaded,max:e.total});
  }
}

Collection.prototype.addLayerForm = function(schema){
  form = "";
  for(i=0; i<schema["layers"].length;i++){
    form = form + '<div><h5>' + schema["layers"][i]["name"] + '</h5>';
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j];
      myField = new Field(field);
      form = form + myField.getField();
    }
    form = form + "</div>";
  }
  return form;
}

Collection.prototype.handleFieldUI = function(schema){
  
  for(i=0; i<schema["layers"].length;i++){
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j];
      myField = new Field(field);
      myField.completeFieldRequirement();
    }
    form = form + "</div>";
  }
}

Collection.prototype.addDataToCollectionList = function(collection_schema){
  
  for(var i=0; i< collection_schema.length; i++){
    if(collection_schema.length > 1 && i == 0){
      classListName = "ui-first-child" 
    }
    else if(collection_schema.length > 1 && i == (collection_schema.length - 1)){
      classListName = "ui-last-child"
    }
    else{
      classListName = ""
    }
    item = Collection.prototype.getListCollectionTemplate(collection_schema[i], classListName)
    $("#listview").append(item);
  }
  
}

Collection.prototype.getListCollectionTemplate = function(collection, classListName){
  item = '<li data-corners="false" data-shadow="false" data-iconshadow="true" data-wrapperels="div" data-icon="arrow-r" data-iconpos="right" data-theme="c" class="ui-btn ui-btn-up-c ui-btn-icon-right ui-li-has-arrow ui-li ' + classListName + '" >' + 
            '<div class="ui-btn-inner ui-li">' + 
              '<div class="ui-btn-text">' +
                '<a style="cursor: pointer;" onclick="Collection.prototype.showListSites(' + collection["id"] + ')"' + ' href="javascript:void(0)" class="ui-link-inherit">' + collection["name"] + '</a>' + 
              '</div>' + 
              '<span class="ui-icon ui-icon-arrow-r ui-icon-shadow">&nbsp;</span>' +
            '</div>' +
          '</li>';
  return item;
}

Collection.prototype.getListSiteTemplate = function(collectionId, site, classListName){
  item = '<li data-corners="false" data-shadow="false" data-iconshadow="true" data-wrapperels="div" data-icon="arrow-r" data-iconpos="right" data-theme="c" class="ui-btn ui-btn-up-c ui-btn-icon-right ui-li-has-arrow ui-li ' + classListName + '" >' + 
            '<div class="ui-btn-inner ui-li">' + 
              '<div class="ui-btn-text">' +
                '<a style="cursor: pointer;" onclick="Collection.prototype.showSite(' + collectionId + ',' + site["id"] + ')"' + ' href="javascript:void(0)" class="ui-link-inherit">' + site["name"] + '</a>' + 
              '</div>' + 
              '<span class="ui-icon ui-icon-arrow-r ui-icon-shadow">&nbsp;</span>' +
            '</div>' +
          '</li>';
  return item;
}

Collection.prototype.showListSites = function(collectionId){
  $.mobile.saving('show');
  $("#listSitesView").html("");
  window.currentCollectionId = collectionId;
  Collection.clearFormData();
  $.ajax({
    url: "/mobile/collections/" + collectionId + "/sites.json",
    success: function(sites) {
      for(var i=0; i< sites.length; i++){
        if(sites.length > 1 && i == 0){
          classListName = "ui-first-child" 
        }
        else if(sites.length > 1 && i == (sites.length - 1)){
          classListName = "ui-last-child"
        }
        else{
          classListName = ""
        }
        item = Collection.prototype.getListSiteTemplate(collectionId, sites[i], classListName)
        $("#listSitesView").append(item);
      }
      Collection.hidePages();
      $("#mobile-list-sites-main").show();
      schema = Collection.getSchemaByCollectionId(collectionId);
      $("#collectionTitle").html(schema["name"]);
      $.mobile.saving('hide');
    }
  });
}


Collection.prototype.applyBrowserLocation = function(){
  Collection.prototype.getLocation();
}

Collection.prototype.showError = function(error){
  switch(error.code){
    case error.PERMISSION_DENIED:
      x.innerHTML="User denied the request for Geolocation."
      break;
    case error.POSITION_UNAVAILABLE:
      x.innerHTML="Location information is unavailable."
      break;
    case error.TIMEOUT:
      x.innerHTML="The request to get user location timed out."
      break;
    case error.UNKNOWN_ERROR:
      x.innerHTML="An unknown error occurred."
      break;
  }
}

Collection.prototype.getLocation = function(){
  if (navigator.geolocation){
    navigator.geolocation.getCurrentPosition(Collection.prototype.showPosition, Collection.prototype.showError);
  }
  else{
    x.innerHTML="Geolocation is not supported by this browser.";
  }
}

Collection.prototype.setFieldFocus = function(fieldId,fieldCode, fieldKind){
  $("div,span").removeClass('ui-focus');
  fieldValue = Collection.prototype.setFieldValueByKind(fieldKind, fieldCode);
  fieldLogics = Collection.prototype.getFieldLogicByFieldId(fieldId);

  for(i=0; i<fieldLogics.length; i++){
    if(fieldLogics[i]["field_id"] != null){
      if(fieldLogics[i]["value"] == fieldValue){       
        fieldFocus = Collection.prototype.findFieldById(fieldLogics[i]["field_id"]); 
        Collection.prototype.setFieldFocusStyleByKind(fieldFocus);
        return;
      }
    }
  }
}

Collection.prototype.setFieldFocusStyleByKind = function(fieldFocus){
  if(fieldFocus['kind'] == 'select_many'){
    $("[name='properties["+fieldFocus['id']+"][]']").first().parent().addClass('ui-focus');
    $("[name='properties["+fieldFocus['id']+"][]']").first().focus();
  }else{
    $('#'+fieldFocus["code"]).parent().addClass('ui-focus');
    $('#'+fieldFocus["code"]).focus();    
  }
}

Collection.prototype.setFieldValueByKind = function(fieldKind, fieldCode){
  if(fieldKind == 'yes_no'){
    if($( "#"+fieldCode+":checked").length == 1){
      value = 0;
    }else{
      value = 1;
    }    
  }else if(fieldKind == 'select_one'){
    value = fieldCode;
  }  

  return value;
}

Collection.prototype.findFieldById = function(fieldId){
  schema = Collection.getSchemaByCollectionId(window.currentCollectionId);
  for(i=0; i<schema["layers"].length;i++){
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j];   
      if(field["id"] == fieldId){
        return field;
      }
    }
  }
}

Collection.prototype.getFieldLogicByFieldId = function(fieldId){
  schema = Collection.getSchemaByCollectionId(window.currentCollectionId);
  for(i=0; i<schema["layers"].length;i++){
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j];   
      if(field["id"] == fieldId){
        return field["config"]["field_logics"];
      }
    }
  }
}

Collection.prototype.showPosition = function(position){
  $("#lat").val(position.coords.latitude);
  $("#lng").val(position.coords.longitude);
}

Collection.prototype.goHome = function(){
  $("#mobile-collections-main").show();
  $("#mobile-sites-main").hide();
  $("#name").val("");
}

Collection.hidePages = function(){
  var pages = ["#map-page", "#mobile-collections-main", "#mobile-sites-main", "#mobile-list-sites-main"];
  for(var i=0; i<pages.length; i++) {
    $(pages[i]).hide();
  }
}

Collection.showCollectionPage = function(){
  Collection.hidePages();
  $("#mobile-collections-main").show();
}

Collection.mapContainer = {} 

Collection.hideMapPage = function(){
  Collection.hidePages();
}

Collection.showMapPage = function() {
  Collection.hidePages();
  Collection.mapContainer.setLatLng( $("#lat").val(),$("#lng").val());
  $("#map-page").show();
}

Collection.showMainSitePage = function(){
  Collection.hidePages();
  $("#lat").val(Collection.mapContainer.currentLat);
  $("#lng").val(Collection.mapContainer.currentLng);
  $("#mobile-sites-main").show();
}

Collection.mapContainer.setLatLng = function(lat,lng){
  if(lat && lng) {
    Collection.mapContainer.currentLat = parseFloat(lat) ;
    Collection.mapContainer.currentLng = parseFloat(lng) ;
  }
  Collection.mapContainer.moveToCurrentMarker();
}

Collection.mapContainer.moveToCurrentMarker = function(){
  if(Collection.mapContainer.currentMarker)
    Collection.mapContainer.currentMarker.setMap(null)
  Collection.mapContainer.createCurrentMarker(); 
  
  var point = Collection.mapContainer.currentMarker.getPosition();
  Collection.mapContainer.map.panTo(point);
}

Collection.mapContainer.createCurrentMarker = function() {
  var latLng = new google.maps.LatLng(Collection.mapContainer.currentLat, Collection.mapContainer.currentLng); 
  Collection.mapContainer.currentMarker = new google.maps.Marker({
        position: latLng,
        map: Collection.mapContainer.map,
        title: "Drag this to new position",
        draggable: true
  });

  google.maps.event.addListener(Collection.mapContainer.currentMarker, 'dragend', function (event) {
    var lat = Collection.mapContainer.currentMarker.getPosition().lat();
    var lng = Collection.mapContainer.currentMarker.getPosition().lng();

    Collection.mapContainer.currentLat = lat ;
    Collection.mapContainer.currentLng = lng ;

    var point = Collection.mapContainer.currentMarker.getPosition();
    Collection.mapContainer.map.panTo(point);

  });
}

Collection.mapContainer.currentLatLng = function(){
  Collection.mapContainer.currentLat = Collection.mapContainer.currentLat || 10.803631 ;
  Collection.mapContainer.currentLng = Collection.mapContainer.currentLng || 103.793335;

   return new google.maps.LatLng( Collection.mapContainer.currentLat, Collection.mapContainer.currentLng);
}

Collection.createMap = function(canvasId){
  var latLng = Collection.mapContainer.currentLatLng();
  var myOptions = {
        zoom: 10,
        center: latLng,
        mapTypeId: google.maps.MapTypeId.ROADMAP
  };
    
  Collection.mapContainer.map = new google.maps.Map($(canvasId)[0], myOptions);
  Collection.mapContainer.createCurrentMarker();
  Collection.mapContainer.refresh();
}

Collection.assignSite = function(site){
  Collection.clearFormData();
  window.currentSiteId = site["id"]
  $("#name").val(site["name"]);
  $("#lat").val(site["lat"]);
  $("#lng").val(site["lng"]);
  focusSchema = Collection.getSchemaByCollectionId(window.currentCollectionId);
  var currentSchemaData = jQuery.extend(true, {}, focusSchema);
  $("#title").html(currentSchemaData["name"]);
  fieldHtml = Collection.editLayerForm(currentSchemaData, site["properties"]);
  $("#fields").html(fieldHtml);
  Collection.prototype.handleFieldUI(currentSchemaData);
}

Collection.clearFormData = function(){
  $("#fields").html("");
  $("#name").val("");
  $("#lat").val("");
  $("#lng").val("");
  window.currentSiteId = null;
}

Collection.editLayerForm = function(schema, properties){
  form = "";
  for(i=0; i<schema["layers"].length;i++){
    form = form + '<div><h5>' + schema["layers"][i]["name"] + '</h5>';
    for(j=0; j<schema["layers"][i]["fields"].length; j++){
      var field = schema["layers"][i]["fields"][j]
      for(var key in properties){
        if(key == schema["layers"][i]["fields"][j]["id"]){
          field["value"] = properties[key];
        }
      }
      myField = new Field(field);
      form = form + myField.getField();
    }
    form = form + "</div>";
  }
  return form;
}

Collection.mapContainer.refresh =  function(){
  setTimeout(function() {
    google.maps.event.trigger(Collection.mapContainer.map,'resize');
    $("#map-page").hide();
  }, 500);
}


Collection.prototype.showSite = function(collectionId, siteId){
  $.mobile.saving('show');
  $("#listSitesView").html("");
  $.ajax({
    url: "/mobile/collections/" + collectionId + "/sites/" + siteId + ".json",
    success: function(site) {
      Collection.hidePages();
      Collection.assignSite(site);
      $("#mobile-sites-main").show();
      $.mobile.saving('hide');
    }
  });
}

Collection.prototype.getFormValue = function(){
  var site = {};
  var properties = {};
  var elements = $("#formSite")[0].elements;
  var propertyIds = []
  for(var i=0; i< elements.length; i++){
    if(elements[i].name.indexOf("properties") == 0 ){
      index = elements[i].name.replace(/[^0-9]/g, '')
      if($.inArray(index, propertyIds) == -1){
        switch(elements[i].getAttribute("datatype")){
          case "photo":
            if(elements[i].getAttribute("data") != null){
              properties[index] = elements[i].getAttribute("data");
            }              
            break;
          case "select_many":
            if(elements[i].checked && (elements[i].value != null || elements[i].value != "")){
              properties[index] = elements[i].value;         
            }
            break;
          case "yes_no":
            if(elements[i].checked){
              properties[index] = elements[i].checked;
            }
            break;
          default:
            if(elements[i].value != null || elements[i].value != ""){
              properties[index] = elements[i].value;
            }            
        }
        propertyIds.push(index);     
      }
      else{
        if(elements[i].getAttribute("datatype") == "select_many" && elements[i].checked && elements[i].value != null){
          if(!(Object.prototype.toString.call( properties[index] ) === '[object Array]') && properties[index] != null){
            properties[index] = [parseInt(properties[index])];
          }
          else if (!(Object.prototype.toString.call( properties[index] ) === '[object Array]') && properties[index] == null){
            properties[index] = [];
          }
          properties[index].push(parseInt(elements[i].value));
        }
      }
    }
    else{
      if(elements[i].name != ""){
        site[elements[i].name] = elements[i].value;
      }      
    }
  }
  site["properties"] = properties;
  return site;
}

Collection.prototype.handleFileUpload = function(el){
  var file = el.files[0];
  var reader = new FileReader();
  reader.readAsDataURL(file);
  reader.onload = function (event) {    
    el.setAttribute('data', reader.result);
  };
}

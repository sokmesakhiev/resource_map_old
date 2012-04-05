$ ->
  module 'rm'
  
  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.membersViewModel = new rm.MembersViewModel
  
  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    
    
    #$.get "/collections/" + rm.membersViewModel.collectionId + "/memberships.json", (memberships) ->
      #rm.membersViewModel = new MembersViewModel
      
      #rm.membersViewModel.initialize current_user.id, collection.id, admin, memberships, collection.layers
      
      #rm.membersViewModel.assignparams #{current_user.id}, #{collection.id}, #{collection_admin?}, #{collection.layers.map{|x| {id: x.id, name: x.name}}.to_json}
      #rm.membersViewModel.initialize memberships
      #ko.applyBindings rm.membersViewModel


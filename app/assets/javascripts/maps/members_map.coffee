$ ->
  module 'rm'
  
  rm.EventDispatcher.bind rm.SystemEvent.GLOBAL_MODELS, (event) ->
    rm.membersViewModel = new rm.MembersViewModel
  
  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    #ko.applyBindings rm.membersViewModel



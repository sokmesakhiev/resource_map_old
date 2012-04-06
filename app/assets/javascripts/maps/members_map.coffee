$ ->
  module 'rm'
  rm.EventDispatcher.bind rm.SystemEvent.INITIALIZE, (event) ->
    $.get "/collections/#{rm.membersViewModel.param_collectionId}/memberships.json", (memberships) ->
      rm.membersViewModel.viewModel rm.membersViewModel.param_admin, memberships, rm.membersViewModel.param_admin
      ko.applyBindings rm.membersViewModel
      $('.hidden-until-loaded').show()

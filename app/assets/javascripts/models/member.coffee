#= require models/expandable
$ ->
  module 'rm'

  rm.Member = class Member extends rm.Expandable
    constructor: (data) ->
      super
      @userId = ko.observable data?.user_id
      @userDisplayName = ko.observable data?.user_display_name
      @admin = ko.observable data?.admin
      @layers = ko.observableArray $.map(data?.layers ? [], (x) => new LayerMember(x))

      @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
      @isCurrentUser = ko.computed => window.userId == @userId()

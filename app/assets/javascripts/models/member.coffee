$ ->
  module 'rm'

  rm.Member = class Member
    constructor: (data) ->
      @name = ko.oberverable data?.name
    
    showMe: ->
      alert 'yeah'

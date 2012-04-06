$ ->
  module 'rm'
  rm.Expandable = class Expandable
    constructor: ->
      @expanded = ko.observable false
    toggleExpanded: => @expanded(!@expanded())

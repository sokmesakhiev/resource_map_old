$ ->
  module 'rm'

  rm.bootstrap = ->
    systemEvent = new rm.SystemEvent
    rm.EventDispatcher.trigger rm.SystemEvent.GLOBAL_MODELS, systemEvent
    rm.EventDispatcher.trigger rm.SystemEvent.INITIALIZE, systemEvent

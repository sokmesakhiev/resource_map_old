#= require view_models/collections_view_model

describe 'CollectionsViewModel', ->
  beforeEach ->
    spyOn rm.CollectionsViewHelper, 'adjustContainerSize'
    @subject = new rm.CollectionsViewModel

  it 'should be in map mode', ->
    expect(@subject.showingMap()).toBeTruthy()

  it 'should redirect to new_collection_url', ->
    spyOn rm.Utils, 'redirect'
    @subject.createCollection()
    expect(rm.Utils.redirect).toHaveBeenCalledWith '/collections/new'

  describe '.showTable', ->
    beforeEach ->
      @subject.showTable()

    it 'should be in table mode', ->
      expect(@subject.showingMap()).toBeFalsy()

  describe '.showMap', ->
    beforeEach ->
      spyOn rm.EventDispatcher, 'trigger'
      @subject.collections [new rm.Collection({ name: 'Clinic', lat: 10, lng: 90 })]
      @subject.showMap()

    it 'should be in map mode', ->
      expect(@subject.showingMap()).toBeTruthy()

    it 'should dispatch google_maps_load event', ->
      event = new rm.GoogleMapsEvent 10, 90
      expect(rm.EventDispatcher.trigger).toHaveBeenCalledWith 'GoogleMapsEvent:LOAD', event

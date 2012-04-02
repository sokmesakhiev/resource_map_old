#= require view_models/collections_view_model

describe 'CollectionsViewModel', ->
  beforeEach ->
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
      @subject.showMap()

    it 'should be in map mode', ->
      expect(@subject.showingMap()).toBeTruthy()

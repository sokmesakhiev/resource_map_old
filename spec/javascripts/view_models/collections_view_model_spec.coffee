#= require view_models/collections_view_model

describe 'CollectionsViewModel', ->
  beforeEach ->
    @subject = new rm.CollectionsViewModel

  it 'should redirect to new_collection_url', ->
    spyOn rm.Utils, 'redirect'
    @subject.createCollection()

    expect(rm.Utils.redirect).toHaveBeenCalledWith '/collections/new'

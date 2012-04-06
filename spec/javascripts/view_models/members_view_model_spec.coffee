#= require view_models/members_view_model

describe 'MemberViewModel', ->
  beforeEach ->
    @layer = []
    @collectionId =1
    @admin = true
    @subject = new rm.MembersViewModel(@collectionId, @admin, @layer)

  it 'should assign (collectionId, admin, layers) parameter after instantiate MemberViewModel', ->
    expect(@subject.param_admin).toBe(@admin)
    expect(@subject.param_collectionId).toBe(@collectionId)
    expect(@subject.param_layers).toBe(@layer)

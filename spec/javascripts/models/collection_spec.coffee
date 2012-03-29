describe 'Collection', ->
  beforeEach ->
    @collection = new rm.Collection { name: 'Clinic' }

  it 'should have #name', ->
    expect(@collection.name()).toEqual 'Clinic'

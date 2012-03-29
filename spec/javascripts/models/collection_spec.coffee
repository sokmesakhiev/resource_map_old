#= require models/collection

describe 'Collection', ->
  beforeEach ->
    @subject = new rm.Collection { name: 'Clinic' }

  it 'should has name', ->
    expect(@subject.name()).toEqual 'Clinic'

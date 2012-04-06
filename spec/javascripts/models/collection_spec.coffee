#= require models/collection

describe 'Collection', ->
  beforeEach ->
    @subject = new rm.Collection { name: 'Clinic', lat: 10, lng: 90 }

  it 'should has name', ->
    expect(@subject.name()).toEqual 'Clinic'

  it 'should has lat', ->
    expect(@subject.lat()).toEqual 10

  it 'should has lng', ->
    expect(@subject.lng()).toEqual 90

  it 'should be checked', ->
    expect(@subject.checked()).toBeTruthy()

  describe 'without coordinate', ->
    beforeEach ->
      @subject = new rm.Collection

    it 'should lat be undefined', ->
      expect(@subject.lat()).toBeUndefined()

    it 'should lng be undefined', ->
      expect(@subject.lng()).toBeUndefined()

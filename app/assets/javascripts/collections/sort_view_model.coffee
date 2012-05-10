$(-> if $('#collections-main').length > 0

  class window.SortViewModel
    @constructorSortViewModel: ->
      @sort = ko.observable()
      @sortDirection = ko.observable()

    @sortBy: (field) ->
      @sortByCode(field.code())

    @sortByName: ->
      @sortByCode('name')

    @sortByDate: ->
      @sortByCode('updated_at', false)

    @sortByCode: (code, defaultOrder = true) ->
      if @sort() == code
        if @sortDirection() == defaultOrder
          @sortDirection(!defaultOrder)
        else
          @sort(null)
          @sortDirection(null)
      else
        @sort(code)
        @sortDirection(defaultOrder)
      @performSearchOrHierarchy()
      @makeFixedHeaderTable()

)
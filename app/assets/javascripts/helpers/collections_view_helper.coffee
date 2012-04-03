$ ->
  module 'rm'

  rm.CollectionsViewHelper =
    # Adjust width to window
    adjustContainerSize: ->
      width = $(window).width()
      containerWidth = width - 80
      containerWidth = 960 if containerWidth < 960

      # Using $(...).width(...) breaks the layout, don't know why
      $('#container').get(0).style.width = "#{containerWidth}px"
      $('#header').get(0).style.width = "#{containerWidth}px"
      $('.BreadCrumb').get(0).style.width = "#{containerWidth - 340}px"
      $('#container .right').get(0).style.width = "#{containerWidth - 334}px"
      $('.tableheader.expanded').get(0).style.width = "#{containerWidth}px" if ($('.tableheader.expanded').length > 0)
      $('#map').get(0).style.width = "#{containerWidth - 350}px" if $('#map').length > 0
      false

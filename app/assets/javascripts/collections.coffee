window.onCollections = (callback) -> $(-> callback() if $('#collections-main').length > 0)


onCollections ->

  # Get collections and start the view model
  $.get "/collections.json", {}, (collections) =>
    window.model = new MainViewModel
    window.model.initialize(collections)
    ko.applyBindings window.model
    window.model.initSammy()

    $('#collections-dummy').remove()
    $('#collections-main').show()
    $('#refine-container').show()

  # Adjust width to window
  window.adjustContainerSize = ->
    width = $(window).width()
    containerWidth = width - 80
    containerWidth = 960 if containerWidth < 960

    $('#container').width(containerWidth)
    $('#header').width(containerWidth)
    $('.BreadCrumb').width(containerWidth - 410)
    $('#right-panel').width(containerWidth - 404)
    $('.tableheader.expanded').width(containerWidth)
    $('#map').width(containerWidth - 420)
    false

  $(window).resize adjustContainerSize
  setTimeout(adjustContainerSize, 100)

  # Hide the refine popup if clicking outside it
  $(window.document).click (event) ->
    $refine = $('.refine')
    $refinePopup = $('.refine-popup')
    unless $refine.get(0) == event.target ||
           $refinePopup.get(0) == event.target ||
           $refine.has(event.target).length > 0 ||
           $refinePopup.has(event.target).length > 0
      window.model.toggleRefinePopup() if window.model.showingRefinePopup()
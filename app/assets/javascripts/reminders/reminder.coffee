onReminders ->
  class @Reminder 
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @reminder_date = ko.observable data?.reminder_date
      @reminder_time = ko.observable data?.reminder_time
      @reminder_datetime = ko.computed =>
        @reminder_date() + " " + @reminder_time()
      @reminder_message = ko.observable data?.reminder_message
      @repeat_id = ko.observable data?.repeat_id
      @collection_id = ko.observable data?.collection_id
      @sites = ko.observable()
      @nameError = ko.computed =>
        if $.trim(@name()).length > 0 
          return null
        else
          return "Reminder's name is missing"
      @sitesError = ko.computed =>
        if $.trim(@sites()).length > 0
          return null
        else
          return "Sites is missing"
      @reminderDateError =ko.computed =>
        if $.trim(@reminder_date()).length > 0
          return null
        else
          return "Reminder's date is missing"

      @reminderMessageError = ko.computed =>
        if $.trim(@reminder_message()).length > 0
          return null
        else
          return "Reminder's message is missing"

      @error = ko.computed =>
        errorMessage = @nameError() || @sitesError() || @reminderDateError() || @reminderMessageError()
        if errorMessage then "Can't save: " + errorMessage else ""

      @valid = ko.computed => !@error()

    toJSON: =>
      name: @name()
      reminder_date: @reminder_date()
      reminder_message: @reminder_message()
      repeat_id: @repeat_id()
      collection_id: @collection_id()

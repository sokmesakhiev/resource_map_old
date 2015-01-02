onReminders ->
  class @Reminder 
    constructor: (data) ->
      @id           = data?.id 
      @collectionId = data?.collection_id 
      @name         = ko.observable data?.name
      @enableCss    = ko.observable 'cb-enable'
      @disableCss   = ko.observable 'cb-disalbe'
      @isAllSites   = ko.observable data.is_all_site ? true
      @targetFor    = ko.computed
        read: -> if @isAllSites() then 'all_sites' else 'some_sites'
        write: (value) -> 
          @isAllSites switch value
            when 'all_sites' then true
            when 'some_sites' then false
            else true
        owner: @
      @sites            = ko.observableArray $.map data.sites ? [], (site) -> new Site site
      @sitesName        = ko.computed => $.map(@sites(), (site) -> site.name).join ', '
      @timeZone = ko.observable data?.time_zone
      @original_reminder_date = ko.observable(data?.reminder_date)
      if @timeZone()
        @reminderDateWithTimeZone = TimeZone.convert_to_reminder_zone(data.reminder_date?.toDate() ? Date.today(), data.time_zone)
        @reminderDateTime = new ReminderDateTime @reminderDateWithTimeZone
      else
        @reminderDateTime = new ReminderDateTime data.reminder_date?.toDate() ? Date.today()
      @reminderDate     = ko.observable @reminderDateTime.getDate()
      @reminderTime     = ko.observable @reminderDateTime.getTime()
      @repeat           = ko.observable data?.repeat
      @repeatName       = ko.computed => @repeat()?.name()
      @reminderMessage  = ko.observable data?.reminder_message
      @status           = ko.observable data?.status
      @statusInit       = ko.computed =>
        if @status()
          @enableCss 'cb-enable selected'
          @disableCss 'cb-disable'
        else
          @enableCss 'cb-enable'
          @disableCss 'cb-disable selected'
      @nameError            = ko.computed => window.t('javascripts.plugins.reminders.name_is_missing') if $.trim(@name()).length == 0
      @sitesError           = ko.computed => window.t('javascripts.plugins.reminders.sites_is_missing') if !@isAllSites() and @sites().length == 0
      @reminderDateError    = ko.computed =>
        if @reminderDate().length == 0 then window.t('javascripts.plugins.reminders.date_is_missing')
        ## FIXME: To check for invalid reminderDate uncomment below line, but Phantomjs used in Jenkins consider 'YYYY-MM-DD' to be invalid date
        # else unless @reminderDate().toDate() then "Reminder's date is invalid"

      @reminderMessageError = ko.computed => window.t('javascripts.plugins.reminders.message_is_missing') if $.trim(@reminderMessage()).length == 0

      @error = ko.computed => @nameError() ? @sitesError() ? @reminderDateError() ? @reminderMessageError()
      @valid = ko.computed => !@error()
      @errorMessage = ko.computed => window.t('javascripts.plugins.reminders.cant_save') + @error()
      @listTimeZone = ko.observableArray(TimeZone.getListTimeZone())
      @userTimeZone = ko.observable()
      


    getListTimeZone: =>
      $.get "/plugin/reminders/get_time_zone.json", (data) =>
        @userTimeZone(data["user_time_zone"])
        @timeZone(@userTimeZone())

    updateReminderDate: ->
      @reminderDateTime.setDate(@reminderDate()).setTime(@reminderTime())

    clone: =>
      new Reminder
        id                : @id
        name              : @name()
        is_all_site       : @isAllSites()
        reminder_date     : @original_reminder_date()
        repeat            : @repeat()
        reminder_message  : @reminderMessage()
        collection_id     : @collectionId
        time_zone         : @timeZone()

    toJson: =>
      id: @id
      name: @name()
      reminder_date: @updateReminderDate().toString()
      reminder_message: @reminderMessage()
      repeat_id: @repeat().id()
      collection_id: @collectionId
      is_all_site: @isAllSites()
      time_zone: @timeZone()
      sites: $.map(@sites(), (x) -> x.id) unless @isAllSites()
   
    getSitesRepeatLabel: =>
      sites = if @isAllSites() then ["all sites"] else $.map @sites(), (site) => site.name
      detail = @repeat().name() + " for " + sites.join(",")

    setStatus: (status, callback) ->
      @status status
      $.post "/plugin/reminders/collections/#{@collectionId}/reminders/#{@id}/set_status.json", {status: status}, callback

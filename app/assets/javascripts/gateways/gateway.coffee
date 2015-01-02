onGateways ->
  class @Gateway
    constructor: (data) ->
      @id                     = data?.id
      @collectionId           = data?.collection_id
      @name                   = ko.observable data?.name
      @serverError            = ko.observable()
      @password               = ko.observable data?.password
      @ticketCode             = ko.observable data?.ticket_code 
      @isEnable               = ko.observable data?.is_enable
      @nuntiumChannelName     = ko.observable data?.name
      @clientConnected        = ko.observable data?.client_connected
      @queuedMessageCount     = ko.observable data?.queued_messages_count
      @nationalGateway        = ko.observable()
      @selectedGateway        = ko.observable(@setupType(data.advanced_setup, data.national_setup))
      @basicSetup             = ko.observable data?.basic_setup
      @advancedSetup          = ko.observable data?.advanced_setup
      @nationalSetup          = ko.observable data?.national_setup
      @viewConfiguration      = ko.observable false
      @processGatewaySelected = ko.computed =>
        switch @selectedGateway()
          when 'basic'
            @basicSetup true
            @advancedSetup false
            @nationalSetup false
          when 'advance' 
            @basicSetup false
            @advancedSetup true
            @nationalSetup false
          when 'national' 
            @basicSetup false
            @advancedSetup false
            @nationalSetup true

      @queuedMessageText      = ko.computed =>
        messageText = 'Client disconected,' + @queuedMessageCount() 
        if data?.queued_messages_count > 1
          return messageText + ' messages pending'
        else
          return messageText + ' message pending'
      
      @phoneNumber            = ko.observable data?.phone_number
      @gateWayURL             = ko.observable data?.gateway_url
      @isTry                  = ko.observable false 
      @nameError              = ko.computed => 
        length = $.trim(@name()).length
        if length < 1
          window.t('javascripts.gateways.form.channel_missing')
        else if length < 4
          window.t('javascripts.gateways.form.channel_require_four_characters')
        else
          null
      
      @passwordError          = ko.computed => 
        return null if !@advancedSetup()
        length = $.trim(@password()).length
        if length < 1
          window.t('javascripts.gateways.form.channel_password_missing')
        else if length < 4
          window.t('javascripts.gateways.form.channel_password_required_four_characters')
        else
          null
      @ticketCodeError        = ko.computed =>
        return null if !@basicSetup()
        length = $.trim(@ticketCode()).length
        if length < 1
          window.t('javascripts.gateways.form.sms_gateway_missing')
        else if length != 4
          window.t('javascripts.gateways.form.sms_gateway_key_must_be_four')
        else 
          null

      @destinationPhoneNumberError            = ko.computed =>
        return null if !@isTry()
        length = $.trim(@tryPhoneNumber()).length
        if length < 1
          window.t('javascripts.gateways.form.destination_phone_missing')       
        else 
          null
      
      @phoneNumberError       = ko.computed =>
        return @destinationPhoneNumberError() if @destinationPhoneNumberError()

      @error                  = ko.computed => 
        return @nameError() if @nameError()
        return @passwordError() if @passwordError()
        return @ticketCodeError() if @ticketCodeError()
        return @serverError() if @serverError()
      
      @enableCss              = ko.observable 'cb-enable'
      @disableCss             = ko.observable 'cb-disalbe'
      @status                 = ko.observable data?.is_enable
      @statusInit             = ko.computed =>
        if @status()
          @enableCss 'cb-enable selected'
          @disableCss 'cb-disable'
        else
          @enableCss 'cb-enable'
          @disableCss 'cb-disable selected'
      
      @valid                  = ko.computed => not @error()?
      @validPhoneNumber       = ko.computed => not @phoneNumberError()?
      @tryPhoneNumber         = ko.observable()
    
    toJson: ->
      id                      : @id
      collection_id           : @collectionId
      name                    : if @nationalSetup() then @nationalGateway().code else @name()
      basic_setup             : @basicSetup()
      is_enable               : @isEnable()
      advanced_setup          : @advancedSetup()
      national_setup          : @nationalSetup()
      #nuntium_channel_name    : @nuntiumChannelName()
      password                : @password()
      ticket_code             : @ticketCode()

    clone: =>
      new Gateway
        id                      : @id
        name                    : @name()
        basic_setup             : @basicSetup()
        advanced_setup          : @advancedSetup()
        national_setup          : @nationalSetup()
        nuntium_channel_name    : @nuntiumChannelName()
        gateway_url             : @gateWayURL() 
        password                : @password()
        ticket_code             : @ticketCode()
        queued_messages_count   : @queuedMessageCount()

    setStatus: (status, callback) ->
      @status status
      $.post "/gateways/#{@id}/status.json", {status: status}, callback 

    setupType: (advanced, national) ->
      if advanced
        'advanced'
      else if national
        'national'
      else
        'basic'



module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  M = env.matcher
  _ = require('lodash')
  Error = require('./error')(env)
  Appliances = require('./appliances')(env)
  HomeConnectAPI = require('./homeconnect_api.js')
  storage = require 'node-persist'


  class HomeconnectPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>

      @pluginConfigDef = require './pimatic-home-connect-config-schema'
      @deviceConfigDef = require("./device-config-schema")

      @error = new Error.Error()
      @homeconnect = null
      @connected = false

      @simulation = if @config.simulation? then @config.simulation else true
      @clientId = if @simulation then @config.clientIdSim else @config.clientId
      @clientSecret = if @simulation then @config.clientSecretSim else @config.clientSecretSim

      @framework.on 'after init', ()=>
        @emit 'status', 'Initializing...'
        storage.init()
        .then((resp)=>
          #env.logger.debug "Storage initialized" + JSON.stringify(resp,null,2)
          storage.getItem('tokens')
        )
        .then((savedTokens) =>
          #check if savedTokens are expired
          #env.logger.info "savedTokens.timestamp: " + savedTokens.timestamp
          #env.logger.info "1000*savedTokens.expires_in: " + 1000*savedTokens.expires_in
          #env.logger.info "Date.now(): " + Date.now()

          if (savedTokens.timestamp + 1000*savedTokens.expires_in) > Date.now() or not savedTokens?
            _savedTokens = null # token expired
          else
            _savedTokens = savedTokens
          #env.logger.debug "Stored tokens retrieved"  + JSON.stringify(savedTokens,null,2)
          @homeconnect = new HomeConnectAPI({
            log:        env.logger,
            clientID:   @clientId,
            clientSecret: @clientSecret
            simulator: @simulation,
            savedAuth:  _savedTokens
          }).on('auth_save', (tokens) =>
            storage.setItem('tokens', tokens)
            env.logger.debug 'Tokens saved'
          ).on('auth_uri', (uri) =>
            @emit 'authorise', uri
            @emit 'status', "Please authorise using Link in label"
            env.logger.info "Auth_uri: " + uri
          )
          @homeconnect.waitUntilAuthorised()
          .then(()=>
            @connected = true
            @homeconnect.getAppliances()
            .then((apps)=>
              env.logger.info "Appliances: " + JSON.stringify(apps,null,2)
              @emit 'homeconnect', 'online'
              @emit 'status', (if @simulation then "simulation" else "live") + ", authorisation ok"
              @emit 'authorise', '' # clear authorisation uri
            )
          )
        )

      @supportedTypes = ["CoffeeMaker","Oven","Washer","Dishwasher", "FridgeFreezer","Dryer"]

      @framework.deviceManager.registerDeviceClass('HomeconnectManager', {
        configDef: @deviceConfigDef.HomeconnectManager,
        createCallback: (config, lastState) => new HomeconnectManager(config, lastState, @, @framework)
      })
      @framework.deviceManager.registerDeviceClass('HomeconnectDevice', {
        configDef: @deviceConfigDef.HomeconnectDevice,
        createCallback: (config, lastState) => new HomeconnectDevice(config, lastState, @, @framework)
      })

      @framework.on 'destroy', () =>
        @removeAllListeners()

      @framework.on 'deviceAdded', (device) =>
        if @connected and device.config.class is "HomeconnectDevice"
          device.emit 'connectdevice', ''

      @framework.ruleManager.addActionProvider(new HomeconnectActionProvider(@framework))

      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-home-connect', 'Searching for new devices'
        if @connected and @homeconnect?
          @homeconnect.getAppliances() #command('default', 'get_home_appliances')
          .then((appliances) =>
            for appliance in appliances
              _did = (appliance.haId).toLowerCase()
              if _.find(@framework.deviceManager.devicesConfig,(d) => d.id.indexOf(_did)>=0)
                env.logger.info "Device '" + _did + "' already in config"
              else
                if appliance.type in @supportedTypes
                  config =
                    id: _did
                    name: appliance.name
                    class: "HomeconnectDevice"
                    haid: appliance.haId
                    hatype: appliance.type
                    brand: appliance.brand
                    enumber: appliance.enumber
                    vib: appliance.vib
                    simulated: @simulation
                  @framework.deviceManager.discoveredDevice( "Home-Connect", config.name, config)
                else
                  env.logger.info "Appliance type #{appliance.type} not implemented."
                  #env.logger.info "Appliance '" + JSON.stringify(appliance,null,2)
          )
          .catch((error)=>
            @error.errorHandler(error)
          )
        else
          env.logger.info "Home-connect offline"
      )

  class HomeconnectManager extends env.devices.Device

    constructor: (config, lastState, @plugin, @framework) ->
      @config = config
      @id = @config.id
      @name = @config.name
      @error = @plugin.error


      @attributes = {}
      @attributeValues = {}

      #generic attributes
      attributesGeneric = ["status"]
      for _attr in attributesGeneric
        do (_attr) =>
          @attributes[_attr] =
            description: _attr
            type: "string"
            label: _attr
            acronym: _attr
          @attributeValues[_attr] = ""
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )

      @plugin.on 'authorise', (uri) =>
        env.logger.info "Authorise uri " + uri
        @config.xLink = uri

      @plugin.on 'status', (status) =>
        @setAttr("status", status)

      super()

    setAttr: (attr, _status) =>
      unless @attributeValues[attr] is _status
        #env.logger.debug "attribute '" + attr + "' with type '" + @attributes[attr].type + "', is set to " + _status
        @attributeValues[attr] = _status
        @emit attr, _status

    destroy: () =>
      super()


  class HomeconnectDevice extends env.devices.Device

    constructor: (config, lastState, @plugin, @framework) ->
      @config = config
      @id = @config.id
      @error = @plugin.error

      if @_destroyed
        return

      @name = @config.name
      @haid = @config.haid
      #@homeconnect = @plugin.homeconnect
      @hatype = @config.hatype


      switch @hatype
        when "CoffeeMaker"
          @deviceAdapter = new Appliances.CoffeeMaker()
        when "Oven"
          @deviceAdapter = new Appliances.Oven()
        when "Washer"
          @deviceAdapter = new Appliances.Washer()
        when "Dishwasher"
          @deviceAdapter = new Appliances.Dishwasher()
        when "FridgeFreezer"
          @deviceAdapter = new Appliances.FridgeFreezer()
        when "Dryer"
          @deviceAdapter = new Appliances.Dryer()
        else
          env.logger.debug "Device type #{@hatype} not yet supported"
          return

      @attributes = {}
      @attributeValues = {}

      #generic attributes
      attributesGeneric = ["program", "status"]
      for _attr in attributesGeneric
        do (_attr) =>
          @attributes[_attr] =
            description: _attr
            type: "string"
            label: _attr
            acronym: _attr
          @attributeValues[_attr] = ""
          @_createGetter(_attr, =>
            return Promise.resolve @attributeValues[_attr]
          )

      if @plugin.simulation and not @config.simulated 
        env.logger.debug "Live device '#{@id}'' not started because of simulation mode"
        @setAttr("status", 'offline')
        return
      if not @plugin.simulation and @config.simulated
        env.logger.debug "Simulated device '#{@id}'' not started because of live mode"
        @setAttr("status", 'offline')
        return

      attributesToBeAdded = [
        @deviceAdapter.supportedOptions,
        @deviceAdapter.supportedEvents,
        @deviceAdapter.supportedStatus
      ]
      for supportedAttributes in attributesToBeAdded
        # appliance option specific attributes
        for _attr in supportedAttributes #@deviceAdapter.supportedOptions
          do (_attr) =>
            @attributes[_attr.name] =
              description: _attr.name
              type: _attr.type
              label: _attr.name
              acronym: _attr.name
              unit: _attr.unit
            @attributeValues[_attr.name] = _attr.default
            @_createGetter(_attr.name, =>
              return Promise.resolve @attributeValues[_attr.name]
            )

      @plugin.on 'homeconnect', (state) =>
        switch state
          when "online"
            @emit 'connectdevice'
          when "offline"
            env.logger.debug "Homeconnect offline"
          else
            env.logger.debug "Unknown homeconnect state received: " + state

      @on 'connectdevice', @onConnectDevice
      @on 'deviceconnected', @onDeviceConnected

      super()

    onConnectDevice: () =>
      checkConnected = () =>
        @plugin.homeconnect.getAppliance(@haid)
        .then((status) =>
          env.logger.debug "STATUS: " + JSON.stringify(status,null,2)
          if status.connected
            env.logger.debug "#{@hatype} #{@id} is connected "
            @setAttr("status","connected")
            @emit 'deviceconnected', ""
            clearTimeout(@checkConnectedTimer)
          else
            @checkConnectedTimer = setTimeout(checkConnected,10000)
        )
        .catch((err) =>
          env.logger.debug "Retry checkConnected #{@hatype} #{@id} " + err
          @checkConnectedTimer = setTimeout(checkConnected,10000)
        )
      if @plugin.homeconnect?
        checkConnected()
      else
        @checkConnectedTimer = setTimeout(checkConnected,10000)

    onDeviceConnected: () =>

      @plugin.homeconnect.getStatus(@haid)
      .then((status)=>
        for i,s of status
          #env.logger.info "Status:::::: " + JSON.stringify(s,null,2)
          @setProgramOrOption(s)
      ).catch((err)=>
        env.logger.debug "Error handled in startup getStatus " + err
      )
      @plugin.homeconnect.getSelectedProgram(@haid)
      .then((program)=>
        #env.logger.info "Program:: " + JSON.stringify(program,null,2)
        @setProgramOrOption(program)
        if program.options?
          for p in program.options
            @setProgramOrOption(p)
      ).catch((err)=>
        env.logger.debug "Error handled in startup getSelectedPrograms" + err
      )
      @plugin.homeconnect.getSelectedProgramOptions(@haid)
      .then((options)=>
        for o in options
          #env.logger.info "Options:::::: " + JSON.stringify(o,null,2)
          @setProgramOrOption(o)
      ).catch((err)=>
        env.logger.debug "Error handled in startupGetSelectedProgramOptions " + err
      )
      @plugin.homeconnect.getSettings(@haid)
      .then((settings)=>
        for i,s of settings
          #env.logger.info "Settings:::::: " + JSON.stringify(s,null,2)
          @setProgramOrOption(s)
      )
      .catch((err)=>
        env.logger.debug "Error handled in startup getSettings " + err
      )
      #env.logger.info "Listening at events from #{@haid}"
      @plugin.homeconnect.on @haid, (eventData) =>
        try
          env.logger.debug "Event received =========== S T A R T ==================="
          env.logger.debug JSON.stringify(eventData,null,2)
          env.logger.debug "Event received ============= E N D ================="
          if eventData.data?.items?.length?
            for d in eventData.data.items
              #env.logger.info "eventD: " + JSON.stringify(d,null,2)
              @setProgramOrOption(d)
              if d.options?
                for option in d.options
                  @setProgramOrOption(option)

          if eventData.data?.items[0]?.key is "BSH.Common.Root.SelectedProgram"
            @plugin.homeconnect.getSelectedProgram(@haid)
            .then((program)=>
              #env.logger.info "Program:: " + JSON.stringify(program,null,2)
              @setProgramOrOption(program)
              if program.options?
                for p in program.options
                  @setProgramOrOption(p)
            )
        catch err
          env.logger.debug "Error handled in received event " + err

    setProgramOrOption: (programOrOption) =>
        _attr = @getProgramOrOption(programOrOption)
        if _attr?
          @setAttr(_attr.name,_attr.value)

    setAttr: (attr, _status) =>
      unless @attributeValues[attr] is _status
        #env.logger.debug "attribute '" + attr + "' with type '" + @attributes[attr].type + "', is set to " + _status
        @attributeValues[attr] = _status
        @emit attr, _status

    getLastValue: (key) =>
      if (String key).indexOf(".")>=0
        _keyArray = key.split(".")
        return _keyArray[_keyArray.length-1]
      else
        return key

    getProgramOrOption: (programOrOption) =>

      if (@deviceAdapter.selectedProgram).indexOf(programOrOption.key)>=0
        if programOrOption.value?
          _value = programOrOption.value
        else
          _value = programOrOption.key
        resultProg =
          name: "program"
          value: @getLastValue(_value)
        return resultProg

      prog = _.find(@deviceAdapter.programs, (p)=> (p.name).indexOf(programOrOption.key)>=0)
      if prog?
        if programOrOption.value?
          _value = programOrOption.value
        else
          _value = programOrOption.key
        resultProg =
          name: "program"
          value: @getLastValue(_value)
        return resultProg

      opt = _.find(@deviceAdapter.supportedOptions, (o)=> (o.key).indexOf(programOrOption.key)>=0)
      if opt?
        resultOpt =
          name: opt.name
        if opt.type is "string"
          resultOpt["value"] = @getLastValue(programOrOption.value)
        else
          resultOpt["value"] = Math.floor(Number programOrOption.value)
        return resultOpt

      stat = _.find(@deviceAdapter.supportedStatus, (s)=> (s.key).indexOf(programOrOption.key)>=0)
      if stat?
        resultStat =
          name: stat.name
        if stat.type is "string"
          resultStat["value"] = @getLastValue(programOrOption.value)
        else
          resultStat["value"] = Math.floor(Number programOrOption.value)
        return resultStat

      try
        evnt = _.find(@deviceAdapter.supportedEvents, (s)=> (s.key).indexOf(programOrOption.key)>=0)
        if evnt?
          resultEvnt =
            name: evnt.name
          if (programOrOption.value).indexOf('BSH.Common.EnumType.EventPresentState')>=0
            _state = @getLastValue(programOrOption.value)
            switch _state
              when "Present"
                resultEvnt["value"] = true
              when "Off"
                resultEvnt["value"] = false
              when "Confirmed"
                resultEvnt["value"] = false
              else
                resultEvnt["value"] = false
          return resultEvnt
      catch err
        env.logger.debug "Error in event handled " + err + ", event data: " + JSON.stringify(evnt,null,2)

      return null

    execute: (device, command, options) =>
      env.logger.debug "@attributes.OperationState '#{@attributeValues.OperationState}', command #{command}"
      #env.logger.info "Execution not implemented"

      #return new Promise((resolve, reject) =>
      #  reject()
      #)
      return new Promise((resolve, reject) =>
        @plugin.homeconnect.getStatusSpecific(@haid,'BSH.Common.Status.LocalControlActive')
        .then((LocalControlActive)=>
          if LocalControlActive 
            env.logger.debug "Action not executed, LocalControl is active, for device #{@haid}"
            reject()
          return @plugin.homeconnect.getStatusSpecific(@haid,'BSH.Common.Status.RemoteControlStartAllowed')
        ).then((RemoteControlStartAllowed)=>
          unless RemoteControlStartAllowed 
            env.logger.debug "RemoteControlStart not allowed for device #{@haid}"
            reject()
          return @plugin.homeconnect.getStatusSpecific(@haid,'BSH.Common.Status.RemoteControlActive')
        ).then((RemoteControlActive)=>
          unless RemoteControlActive
            env.logger.debug "RemoteControlActive not active"
            reject()
        ).catch((err)=>
          env.logger.debug "LocalControlActive status not available"
        )

        @plugin.homeconnect.getStatusSpecific(@haid, 'BSH.Common.Status.OperationState')
        .then((status) =>
          switch command
            when "start"
              activeStates = [
                'BSH.Common.EnumType.OperationState.Ready',
                'BSH.Common.EnumType.OperationState.Pause'
              ]
              if status.value in activeStates
                @plugin.homeconnect.getSelectedProgram(@haid)
                .then((selected)=>
                  #env.logger.info "Selected " + JSON.stringify(selected,null,2)
                  return @plugin.homeconnect.setActiveProgram(@haid,selected.key)
                )
                .then(()=>
                    resolve()
                )
                .catch((err)=>
                  env.logger.error "Error setActiveProgram "
                )
            when "stop"
              activeStates = [
                'BSH.Common.EnumType.OperationState.DelayedStart',
                'BSH.Common.EnumType.OperationState.Run',
                'BSH.Common.EnumType.OperationState.Pause',
                'BSH.Common.EnumType.OperationState.ActionRequired'
              ]
              if status.value in activeStates
                @plugin.homeconnect.stopActiveProgram(@haid)
                .then(()=>
                  resolve()
                )
                .catch((err)=>
                  env.logger.error "Error stopActiveProgram"
                )
              else
                reject()
            when "pause"
              activeStates = [
                'BSH.Common.EnumType.OperationState.Run'
              ]
              if status.value in activeStates
                @plugin.homeconnect.setCommand(@haid,'BSH.Common.Command.PauseProgram')
                .then(()=>
                  resolve()
                )
                .catch((err)=>
                  env.logger.debug  "Handled Error setCommand PauseProgram: #{@haid} " + err.message
                  reject()
                )
            when "resume"
              activeStates = [
                'BSH.Common.EnumType.OperationState.Pause'
              ]
              if status.value in activeStates
                @plugin.homeconnect.setCommand(@haid,"BSH.Common.Command.ResumeProgram")
                .then(()=>
                  resolve()
                )
                .catch((err)=>
                  env.logger.debug "Handled Error setCommand PauseProgram: #{@haid} - " + err.message
                  reject()
                )
            else
              reject()
        )
      )

    destroy:() =>
      clearTimeout(@checkConnectedTimer)
      @removeListener('connectdevice', @onConnectDevice)
      @removeListener('deviceconnected', @onDeviceConnected)
      super()


  class HomeconnectActionProvider extends env.actions.ActionProvider

    constructor: (@framework) ->

    parseAction: (input, context) =>

      homeconnectDevice = null
      homeconnectDevices = _(@framework.deviceManager.devices).values().filter(
        (device) => device.config.class == "HomeconnectDevice"
      ).value()
      @options = []

      setCommand = (command) =>
        @command = command


      m = M(input, context)
        .match('homeconnect ')
        .matchDevice(homeconnectDevices, (m, d) ->
          # Already had a match with another device?
          if homeconnectDevice? and homeconnectDevice.id isnt d.id
            context?.addError(""""#{input.trim()}" is ambiguous.""")
            return
          homeconnectDevice = d
        )
        .or([
          ((m) =>
            return m.match(' start', (m) =>
              setCommand('start')
              match = m.getFullMatch()
            )
          ),
          ((m) =>
            return m.match(' stop', (m) =>
              setCommand('stop')
              match = m.getFullMatch()
            )
           ),
          ((m) =>
            return m.match(' pause', (m) =>
              setCommand('pause')
              match = m.getFullMatch()
            )
          ),
          ((m) =>
            return m.match(' resume', (m) =>
              setCommand('resume')
              match = m.getFullMatch()
            )
          )
        ])

      match = m.getFullMatch()
      if match? #m.hadMatch()
        env.logger.debug "Rule matched: '", match, "' and passed to Action handler"
        return {
          token: match
          nextInput: input.substring(match.length)
          actionHandler: new HomeconnectActionHandler(@framework, homeconnectDevice, @command, @options)
        }
      else
        return null


  class HomeconnectActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @homeconnectDevice, @command, @options) ->

    executeAction: (simulate) =>
      if simulate
        return __("would have cleaned \"%s\"", "")
      else
        @homeconnectDevice.execute(@homeconnectDevice,@command, @options)
        .then(()=>
          return __("\"%s\" Rule executed", @command)
        ).catch((err)=>
          return __("\"%s\" Rule not executed", "")
        )


  homeconnectPlugin = new HomeconnectPlugin
  return homeconnectPlugin

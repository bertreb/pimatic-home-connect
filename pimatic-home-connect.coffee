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

      ###
      @clientId = @config.clientId 
      @clientSecret = @config.clientSecret

      storage.init()
      .then((resp)=>
        env.logger.info "Storage initialized " + JSON.stringify(resp,null,2)
        storage.getItem('tokens')
      )
      .then((savedTokens) =>
        #Connect to the Home Connect cloud
        #env.logger.info "savedTokens: " + JSON.stringify(savedTokens,null,2)
        @homeconnect = new HomeConnectAPI({
            #log:        this.log,
            # User options from config.json
            clientID:   @clientId,
            clientSecret: @clientSecret
            simulator:  true,
            #language:   (this.config.language || {}).api,
            #Saved access and refresh tokens
            savedAuth:  savedTokens
        }).on('auth_save', (tokens) =>
            storage.setItem('tokens', tokens)
            env.logger.info 'Home Connect authorisation token saved'
        ).on('auth_uri', (uri) => 
            #this.schema.setAuthorisationURI(uri);
            #this.log(chalk.greenBright('Home Connect authorisation required.'
            #                           + ' Please visit:'));
            #this.log('    ' + chalk.greenBright.bold(uri));
            env.logger.info "Auth_uri: " + uri
        )
        @homeconnect.waitUntilAuthorised()
        .then(()=>
          @connected = true
          @homeconnect.getAppliances()
          .then((apps)=>
            #env.logger.info "Appliances: " + JSON.stringify(apps,null,2)
            @emit 'homeconnect', 'online'
          )
        )

      )
      ###

      @supportedTypes = ["CoffeeMaker","Oven","Washer","Dishwasher"]

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
        if device.config.class is "HomeconnectDevice"
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
      attributesGeneric = ["authorise"]
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

      @setAttr("authorise","Authorisation ... starting")

      @simulation = if @config.simulation? then @config.simulation else true
      @clientId = if @simulation then @config.clientIdSim else @config.clientId
      @clientSecret = if @simulation then @config.clientSecretSim else @config.clientSecretSim
      @connected = false

      @framework.variableManager.waitForInit()
      .then(()=>
        storage.init()
        .then((resp)=>
          env.logger.info "Storage initialized " + JSON.stringify(resp,null,2)
          storage.getItem('tokens')
        )
        .then((savedTokens) =>
          #Connect to the Home Connect cloud
          #env.logger.info "savedTokens: " + JSON.stringify(savedTokens,null,2)
          @plugin.homeconnect = new HomeConnectAPI({
              #log:        this.log,
              # User options from config.json
              clientID:   @clientId,
              clientSecret: @clientSecret
              simulator:  @simulation,
              #language:   (this.config.language || {}).api,
              #Saved access and refresh tokens
              savedAuth:  savedTokens
          }).on('auth_save', (tokens) =>
              storage.setItem('tokens', tokens)
              env.logger.info 'Home Connect authorisation token saved'
          ).on('auth_uri', (uri) => 
              #this.schema.setAuthorisationURI(uri);
              #this.log(chalk.greenBright('Home Connect authorisation required.'
              #                           + ' Please visit:'));
              #this.log('    ' + chalk.greenBright.bold(uri));
              @setAttr("authorise","Authorisation required ... click Link")
              @xLink = uri
              env.logger.info "Auth_uri: " + uri
          )
          @plugin.homeconnect.waitUntilAuthorised()
          .then(()=>
            @plugin.connected = true
            @plugin.homeconnect.getAppliances()
            .then((apps)=>
              #env.logger.info "Appliances: " + JSON.stringify(apps,null,2)
              @plugin.emit 'homeconnect', 'online'
              @setAttr("authorise",(if @simulation then "Simulation" else "Live") + " Authorisation Ok")
            )
          )
        )
      )
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
      @homeconnect = @plugin.homeconnect
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
        else
          env.logger.debug "Device type #{@hatype} not yet supported"
          return
      
      @attributes = {}
      @attributeValues = {}

      #generic attributes
      attributesGeneric = ["program", "progress", "status"]
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
      
      # appliance option specific attributes
      for _attr in @deviceAdapter.supportedOptions
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

      # appliance status specific attributes
      for _attr in @deviceAdapter.supportedStatus
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
          env.logger.info "STATUS: " + JSON.stringify(status,null,2)
          if status.connected
            env.logger.debug "#{@hatype} #{@id} is connected "
            @setAttr("status","connected")
            @emit 'deviceconnected', ""
          else
            @checkConnectedTimer = setTimeout(checkConnected,10000)
        )
        .catch((err) =>
          env.logger.debug "Retry checkConnected #{@hatype} #{@id} " + err
          @checkConnectedTimer = setTimeout(checkConnected,10000)
        )
      if @homeconnect? 
        checkConnected()
      else
        @checkConnectedTimer = setTimeout(checkConnected,10000)

    onDeviceConnected: () =>
      @plugin.homeconnect.getStatus(@haid)
      .then((status)=>
        for i,s of status
          #env.logger.info "Status:::::: " + JSON.stringify(s,null,2)
          @setProgramOrOption(s)
      )
      @plugin.homeconnect.getSelectedProgram(@haid)
      .then((program)=>
        #env.logger.info "Program:: " + JSON.stringify(program,null,2)
        @setProgramOrOption(program)
        if program.options?
          for p in program.options
            @setProgramOrOption(p)
      )
      @plugin.homeconnect.getSelectedProgramOptions(@haid)
      .then((options)=>
        for o in options
          #env.logger.info "Options:::::: " + JSON.stringify(o,null,2)
          @setProgramOrOption(o)
      )
      @plugin.homeconnect.getSettings(@haid)
      .then((settings)=>
        for i,s of settings
          #env.logger.info "Settings:::::: " + JSON.stringify(s,null,2)
          @setProgramOrOption(s)
      )
      #env.logger.info "Listening at events from #{@haid}"
      @plugin.homeconnect.on @haid, (eventData) =>
        env.logger.info "Event " + JSON.stringify(eventData,null,2) + ", eventData? " + eventData.data?
        if eventData.data?
          for d in eventData.data.items
            #env.logger.info "eventD: " + JSON.stringify(d,null,2)
            @setProgramOrOption(d)
            if d.options?
              for option in d.options
                @setProgramOrOption(option)
        ###
        if eventData.data?.items[0]?.key?
          @plugin.homeconnect.getSelectedProgram(@haid)
          .then((program)=>
            env.logger.info "Program:: " + JSON.stringify(program,null,2)
            @setProgramOrOption(program)
            if program.options?
              for p in program.options
                @setProgramOrOption(p)
          )
        ###


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

      if ("BSH.Common.Option.ProgramProgress").indexOf(programOrOption.key)>=0
        resultPgrss = 
          name: "progress"
          value: programOrOption.value + " " + programOrOption.unit
        return resultPgrss

      return null

  
    execute: (device, command) =>
      env.logger.debug "@attributes.OperationState '#{@attributeValues.OperationState}', command #{command}"
      env.logger.info "Execution not implemented"
      
      return new Promise((resolve, reject) =>
        reject()
      )

      executableCommand = true

      switch command
        when "start"
          if (@attributeValues.OperationState).indexOf("Ready") >= 0
            body = 
              data:
                key: "BSH.Common.Command.StartProgram"
                value: true          
        when "stop"
            body = 
              data:
                key: "BSH.Common.Command.StopProgram"
                value: true
        when "pause"
          if (@attributeValues.OperationState).indexOf("Run") >= 0
            body = 
              data:
                key: "BSH.Common.Command.PauseProgram"
                value: true          
        when "resume"
          if (@attributeValues.OperationState).indexOf("Pause") >= 0
            body = 
              data:
                key: "BSH.Common.Command.ResumeProgram"
                value: true
        else
          executableCommand = false


      return new Promise((resolve, reject) =>
        if executableCommand
          @homeconnect.command('programs', 'start_program', @haid, body)
          .then((res)=>
            #env.logger.info "Device #{device.name}: program '#{command}' started"
            env.logger.info "Program '#{command}' started"
            resolve()            
          )
          .catch((err) =>
            @error.errorHandler(err)
            reject(err)
          )
        else
          #env.logger.info "Device #{device.name}: program '#{command}' not started"
          env.logger.info "Program '#{command}' not started"
          reject()
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

      setCommand = (command) =>
        @command = command

 
      m = M(input, context)
        .match('hc ')
        .matchDevice(homeconnectDevices, (m, d) ->
          # Already had a match with another device?
          if homeconnectDevice? and homeconnectDevices.id isnt d.id
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
          actionHandler: new HomeconnectActionHandler(@framework, homeconnectDevice, @command)
        }
      else
        return null


  class HomeconnectActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @homeconnectDevice, @command) ->

    executeAction: (simulate) =>
      if simulate
        return __("would have cleaned \"%s\"", "")
      else
        @homeconnectDevice.execute(@homeconnectDevice,@command)
        .then(()=>
          return __("\"%s\" Rule executed", @command)
        ).catch((err)=>
          return __("\"%s\" Rule not executed", "")
        )


  homeconnectPlugin = new HomeconnectPlugin
  return homeconnectPlugin

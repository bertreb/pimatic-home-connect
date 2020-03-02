module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  M = env.matcher
  _ = require('lodash')
  HomeConnect = require('home-connect-js')
  Error = require('./error')(env)
  Appliances = require('./appliances')(env)

  class HomeconnectPlugin extends env.plugins.Plugin
    init: (app, @framework, @config) =>

      pluginConfigDef = require './pimatic-home-connect-config-schema'
      @deviceConfigDef = require("./device-config-schema")

      @errorHandler = new Error()

      @clientId = @config.clientId 
      @clientSecret = @config.clientSecret #"a1b2c3d4";
      @simulation = @config.simulation ? pluginConfigDef.properties.simulation.default
      @connected = false
      
      @homeconnect = new HomeConnect(@clientId,@clientSecret)
      @homeconnect.init( isSimulated: @simulation, secret: @framework.config.settings.authentication.secret )
      .then(() =>
        env.logger.debug "Home-connect online"
        @connected = true
        @emit 'homeconnect', 'online'
      )
      .catch((error)=>
        @emit 'homeconnect', 'offline'
        @errorHandler(error)
      )

      @supportedTypes = ["CoffeeMaker","Oven"]

      @framework.deviceManager.registerDeviceClass('HomeconnectDevice', {
        configDef: @deviceConfigDef.HomeconnectDevice,
        createCallback: (config, lastState) => new HomeconnectDevice(config, lastState, @, @framework)
      })

      @framework.on 'destroy', () =>
        @removeAllListeners()

      @framework.ruleManager.addActionProvider(new HomeconnectActionProvider(@framework))

      
      @framework.deviceManager.on('discover', (eventData) =>
        @framework.deviceManager.discoverMessage 'pimatic-home-connect', 'Searching for new devices'
        if @connected and @homeconnect?
          @homeconnect.command('default', 'get_home_appliances')
          .then((appliances) =>
            for appliance in appliances.body.data.homeappliances            
              _did = appliance.haId.toLowerCase()
              if _.find(@framework.deviceManager.devicesConfig,(d) => (d.id).indexOf(_did)>=0)
                env.logger.info "Device '" + _did + "' already in config"
              else
                _class = @getCl(appliance.type)
              if _class?
                config =
                  id: _did
                  name: appliance.name
                  class: _class
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
            @errorHandler(error)
          )
        else
          env.logger.info "Home-connect offline"
      )

    getCl: (type) =>
      if type in Applicances.supportedTypes
        return "HomeconnectDevice"
      else
        return null

  class HomeconnectDevice extends env.devices.Device

    constructor: (config, lastState, @plugin, @framework) ->
      @config = config
      @id = @config.id
      @errorHandler = @plugin.errorHandler

      @name = @config.name
      @haid = @config.haid
      @homeconnect = @plugin.homeconnect
      @hatype = @config.hatype
  
      switch @hatype
        when "CoffeeMaker"
          @deviceAdapter = new Appliances.CoffeeMaker()
        when "Oven"
          @deviceAdapter = new Appliances.Oven()
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

      @plugin.on 'homeconnect', () =>
        checkConnected = () =>
          @homeconnect.command('default', 'get_specific_appliance', @haid)
          .then((status) => 
            #env.logger.info "STATUS: " + JSON.stringify(status,null,2)
            if status.body.data.connected
              env.logger.debug "#{@hatype} #{@id} is connected "
              @setAttr("status","connected")
              @emit 'deviceconnected', ""
            else
              @checkConnectedTimer = setTimeout(checkConnected,5000)
          )
          .catch((err) =>
            env.logger.debug "Retry checkConnected #{@hatype} #{@id} " + err
            @checkConnectedTimer = setTimeout(checkConnected,5000)
          )
        checkConnected()

      @on 'deviceconnected', () =>
        @homeconnect.command('settings', 'get_settings', @haid)
        .then((settings) =>
          #env.logger.debug "#{@hatype} SETTINGS: " + JSON.stringify(settings,null,2)
          data = settings.body.data
          #@setProgramOrOption(data)
          if data.settings?
            for setting in data.settings
              @setProgramOrOption(setting)
          return @homeconnect.command('status_events', 'get_status', @haid)
        )
        .then((status) =>
          #env.logger.info "#{@hatype} STATUS: " + JSON.stringify(status,null,2)
          data = status.body.data
          #@setProgramOrOption(data)
          if data.status?
            for status in data.status
              @setProgramOrOption(status)
          return @homeconnect.command('programs', 'get_selected_program', @haid)
        )
        .then((program) =>
          #env.logger.info "#{@hatype} PROGRAM: " + JSON.stringify(program,null,2)
          data = program.body.data
          @setProgramOrOption(data)
          if data.options?
            for option in data.options
              @setProgramOrOption(option)
        )
        .catch((err) =>
          @errorHandler(err)
        )

        @homeconnect.subscribe(@haid, 'NOTIFY', (info) =>
          data = JSON.parse(info.data)
          #env.logger.info "NOTIFY received from #{@haid}: " + JSON.stringify(data,null,2)
          for item in data.items
            @setProgramOrOption(item)
        )
        @homeconnect.subscribe(@haid, 'STATUS', (info) =>
          data = JSON.parse(info.data)
          #env.logger.info "STATUS received from #{@haid}: " + JSON.stringify(data,null,2)
          for item in data.items
            @setProgramOrOption(item)
        )
        @homeconnect.subscribe(@haid, 'EVENT', (info) =>
          data = JSON.parse(info.data)
          #env.logger.info "EVENT received from #{@haid}: " + JSON.stringify(data,null,2)
          for item in data.items
            @setProgramOrOption(item)
        )
        @homeconnect.subscribe(@haid, 'CONNECTED', () =>
          env.logger.debug "Connected event received"
        )
        @homeconnect.subscribe(@haid, 'DISCONNECTED', () =>
          env.logger.debug "Disconnected event received"
        )
        @homeconnect.subscribe(@haid, 'DEPAIRED', () =>
          env.logger.debug "Depaired event received"
        )
        @homeconnect.subscribe(@haid, 'PAIRED', () =>
          env.logger.debug "Paired event received"
        )
        @homeconnect.subscribe(@haid, 'KEEP-ALIVE', () =>
          #env.logger.debug "Keep-alive event received"
        )

      super()


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
        resultProg =
          name: "program"
          value: @getLastValue(programOrOption.value)
        return resultProg

      prog = _.find(@deviceAdapter.programs, (p)=> (programOrOption.key).indexOf(p.name)>=0)
      if prog?
        resultProg =
          name: "program"
          value: @getLastValue(programOrOption.key)
        return resultProg

      opt = _.find(@deviceAdapter.supportedOptions, (o)=> (programOrOption.key).indexOf(o.key)>=0)
      if opt?
        resultOpt = 
          name: opt.name
        if opt.type is "string"
          resultOpt["value"] = @getLastValue(programOrOption.value)
        else
          resultOpt["value"] = Math.floor(Number programOrOption.value)
        return resultOpt

      stat = _.find(@deviceAdapter.supportedStatus, (s)=> (programOrOption.key).indexOf(s.key)>=0)
      if stat?
        resultStat = 
          name: stat.name
        if stat.type is "string"
          resultStat["value"] = @getLastValue(programOrOption.value)
        else
          resultStat["value"] = Math.floor(Number programOrOption.value)
        return resultStat

      if (programOrOption.key).startsWith("BSH.Common.Option.ProgramProgress")
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

      executableCommand = false

      switch command
        when "pause"
          if (@attributeValues.OperationState).indexOf("Run") >= 0
            executableCommand = true
            body = 
              data:
                key: "BSH.Common.Command.PauseProgram"
                value: true          
        when "resume"
          if (@attributeValues.OperationState).indexOf("Pause") >= 0
            executableCommand = true
            body = 
              data:
                key: "BSH.Common.Command.ResumeProgram"
                value: true

      return new Promise((resolve, reject) =>
        if executableCommand
          @homeconnect.command('programs', 'start_program', @haid, body)
          .then((res)=>
            #env.logger.info "Device #{device.name}: program '#{command}' started"
            env.logger.info "Program '#{command}' started"
            resolve()            
          )
          .catch((err) =>
            @errorHandler(err)
            reject(err)
          )
        else
          #env.logger.info "Device #{device.name}: program '#{command}' not started"
          env.logger.info "Program '#{command}' not started"
          reject()
      )


    destroy:() =>
      clearTimeout(@checkConnectedTimer)
      @removeAllListeners()
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

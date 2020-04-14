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
          if savedTokens?[@clientId]?
            if (savedTokens[@clientId].accessExpires < Date.now())
              _savedTokens = savedTokens[@clientId]
              env.logger.debug "Stored tokens retrieved" #  + JSON.stringify(savedTokens,null,2)
            else
              _savedTokens = null # token expired
              env.logger.debug "Stored tokens expired"
          else
            _savedTokens = null # token expired
            env.logger.debug "No stored tokens"
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
        .catch((err)=>
          env.logger.debug "Error savedTokens handled " + err
        )

      @supportedTypes = ["CoffeeMaker","Oven","Washer","Dishwasher","FridgeFreezer","Dryer","Hood","CleaningRobot"]

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
      @hatype = @config.hatype
      @availableProgramsAndOptions = []

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
        when "Hood"
          @deviceAdapter = new Appliances.Hood()
        when "CleaningRobot"
          @deviceAdapter = new Appliances.CleaningRobot()
        else
          env.logger.debug "Device type #{@hatype} not yet supported"
          return

      @attributes = {}
      @attributeValues = {}

      #generic attributes
      attributesGeneric = [ "status", "program"]
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

    ###
    setAttributesVisibility: () =>
      #env.logger.info "Attributes: " + JSON.stringify(@attributes,null,2)
      @framework.variableManager.waitForInit()
      .then(()=>
        for i, attr of @attributes
          env.logger.info "Attribute " + JSON.stringify(i,null,2)
          unless i is "status" or i is "program"
            _hidden = true
            for program in @availableProgramsAndOptions
              env.logger.info "program: " + JSON.stringify(program,null,2) + ", i: " + i
              if (program.key).indexOf(i)>=0
                env.logger.info "Attribute #{i} is visible"
                _hidden = false
              else
                env.logger.info "Attribute #{i} is hidden"
              for option in program.options
                if (option.key).indexOf(i)>=0
                  env.logger.info "Attribute #{i} is visible"
                  _hidden = false
                else
                  env.logger.info "Attribute #{i} is hidden"
            @attributes[i]["hidden"] = _hidden
      )
    ###
  
    onConnectDevice: () =>
      checkConnected = () =>
        @plugin.homeconnect.getAppliance(@haid)
        .then((status) =>
          #env.logger.debug "STATUS: " + JSON.stringify(status,null,2)
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

      @plugin.homeconnect.getAvailablePrograms(@haid)
      .then((programs)=>
        #env.logger.info "available programs: #{_.size(programs)} " + JSON.stringify(programs,null,2)
        for program, i in programs
          @plugin.homeconnect.getAvailableProgram(@haid,program.key)
          .then((programAndOptions)=>
            @availableProgramsAndOptions.push programAndOptions
            if _.size(@availableProgramsAndOptions) is _.size(programs)
              env.logger.debug "AvailableProgramsAndOptions is ready"
              #@setAttributesVisibility()
          ).catch((err)=>
            env.logger.debug "Error handled in getting available programAndOptions " + err
          )
      ).catch((err)=>
        env.logger.debug "Error handled in getting available programs " + err
      )

      @plugin.homeconnect.getStatus(@haid)
      .then((status)=>
        for i,s of status
          #env.logger.info "Status:::::: " + JSON.stringify(s,null,2)
          @setProgramOrOption(s) if s?
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
          @setProgramOrOption(s) if s?
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
            .catch((err)=>
              env.logger.debug "Handled error getSelectedProgram " + err
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

      if (@deviceAdapter.activeProgram).indexOf(programOrOption.key)>=0
        if programOrOption.value?
          _value = programOrOption.value
        else
          _value = @attributesValues["program"] # use current value
        resultProg =
          name: "program"
          value: @getLastValue(_value)
        return resultProg

      if (@deviceAdapter.selectedProgram).indexOf(programOrOption.key)>=0
        if programOrOption.value?
          _value = programOrOption.value
        else
          _value = @attributesValues["program"] # use current value
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
        if opt.type is "boolean"
          resultOpt["value"] = programOrOption.value
        else if opt.type is "number"
          resultOpt["value"] = Math.floor(Number programOrOption.value)
        else
          resultOpt["value"] = @getLastValue(programOrOption.value)
        return resultOpt

      stat = _.find(@deviceAdapter.supportedStatus, (s)=> (s.key).indexOf(programOrOption.key)>=0)
      if stat?
        resultStat =
          name: stat.name
        if stat.type is "boolean"
          resultStat["value"] = programOrOption.value
        else if stat.type is "number"
          resultStat["value"] = Math.floor(Number programOrOption.value)
        else
          resultStat["value"] = @getLastValue(programOrOption.value)
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
          else
            resultEvnt["value"] = @getLastValue(programOrOption.value)
          return resultEvnt
      catch err
        env.logger.debug "Error in event handled " + err + ", event data: " + JSON.stringify(evnt,null,2)

      return null

    parseProgramAndOptions: (_programAndOptions) =>
      #return new Promise((resolve, reject) =>
        progAndOpts = {}
        try
          parameters = _programAndOptions.split(",")
          for parameter in parameters
            tokens = parameter.split(":")
            par =
              key: tokens[0].trim()
              value: tokens[1].trim()
            progAndOpts[par.key] = par.value

            ###
            invalidProgram = true
            invalidOption = true
            invalidOptionValue = ""
            #env.logger.info "par.key: " + JSON.stringify(par.key,null,2) + ", par.value: " + par.value
            if par.key == "program"
              if _.find(@availableProgramsAndOptions, (a)=> (a.key).indexOf(par.value)>=0)?
                invalidProgram = false
            else
              for program in @availableProgramsAndOptions
                for option in program.options
                  #env.logger.info "option: " + JSON.stringify(option,null,2) + ", par.value: " + par.value
                  if option.unit is "enum"
                    if _.find(option.constraints.allowedvalues, (o)=> (o).indexOf(par.value)>=0)
                      invalidOption = false
                    else
                      invalidOptionValue = par.value
                  if option.type is "Int"
                    min = Number option.constraints.min
                    max = Number option.constraints.max
                    stepsize = if option.constraints.stepsize? then option.constraints.stepsize else 1
                    if (Number par.value) >= min and (Number par.value) <= max and ((Number par.value) / stepsize) % 1 < 0.0001
                      invalidOption = false
                    else
                      invalidOptionValue = par.value
            if invalidProgram
              env.logger.debug "Invalid value #{par.value}"
              return null
            if invalidOption
              env.logger.debug "Invalid option #{}value #{invalidOptionValue}"
              return null
            ###
          env.logger.info "progAndOpts: " + JSON.stringify(progAndOpts,null,2)
          return progAndOpts
        catch err
          env.logger.debug "Handled error in parseProgramAndOptions " + err
          return null


    execute: (device, command, programAndOptions) =>
      return new Promise((resolve, reject) =>
        if @attributeValues.LocalControlActive == true
          env.logger.debug "Action not executed, LocalControl is active, for device #{@haid}"
          reject()
          return
        if @attributeValues.RemoteStart == false
          env.logger.debug "RemoteControlStart not allowed for device #{@haid}"
          reject("RemoteControlStart not allowed")
          return

        #env.logger.info "command: " + command + ", programAndOptions: " + JSON.stringify(programAndOptions,null,2)
        switch command
          when "start"
            activeStates = ['Ready','Pause']
            unless @attributeValues.OperationState in activeStates
              env.logger.debug "No start allowed for device '#{@haid}' when OperationState is '#{@attributeValues.OperationState}'"
              reject("No start allowed for device")
              return
            po = _.find(@availableProgramsAndOptions, (po)=> (po.key).indexOf(@attributeValues["program"])>=0)
            options = []
            for option in po.options
              lastValue = @attributeValues[@getLastValue(option.key)]
              if _.isNumber(lastValue)
                optionValue = Number lastValue
              else
                optionValue = _.find(option.constraints.allowedvalues, (o)=> o.indexOf(@attributeValues[@getLastValue(option.key)]) >=0)
              options.push {key: option.key, value: optionValue}

            @plugin.homeconnect.setActiveProgram(@haid,po.key,options)
            .then(()=>
              resolve()
            )
            .catch((err)=>
              env.logger.error "Error setActiveProgram "
              reject("Error setActiveProgram")
            )
          when "startoptions"
            if programAndOptions?
              _programAndOptions = @parseProgramAndOptions(programAndOptions)
            else
              env.logger.debug "ProgramAndOptions empty" + err
              reject("ProgramAndOptions empty")
              return
            unless _programAndOptions?
              env.logger.debug "ProgramAndOptions '#{_programAndOptions}' not valid" + err
              reject("ProgramAndOptions not valid 1")
              return

            activeStates = ['Ready','Pause']
            unless @attributeValues.OperationState in activeStates
              env.logger.debug "No start allowed for device '#{@haid}' when OperationState is '#{@attributeValues.OperationState}'"
              reject("No start allowed")
              return

            #_programAndOptions = @parseProgramAndOptions(programAndOptions)
            if not _programAndOptions?
              env.logger.debug "ProgramAndOptions '#{_programAndOptions}' not valid" + err
              reject("ProgramAndOptions not valid 2")
              return
            if _programAndOptions["program"]?
              po = _.find(@availableProgramsAndOptions, (po)=> (po.key).indexOf(_programAndOptions["program"])>=0)
              if po?
                _key = po.key
              else
                env.logger.debug "Invalid program name '#{_programAndOptions["program"]}'"
                reject("Invalid program name")
                return
            else
              po = _.find(@availableProgramsAndOptions, (po)=> (po.key).indexOf(@attributeValues["program"])>=0)
              _key = po.key

            options = []
            for option in po.options
              if _programAndOptions[@getLastValue(option.key)]?
                _parameter =
                  key: option.key
                if option.type is "Int"
                  _parameter["value"] = Number _programAndOptions[@getLastValue(option.key)]
                else
                  if option.type is "Boolean"
                    _parameter["value"] = Boolean _programAndOptions[@getLastValue(option.key)]
                  else
                    _parameter["value"] = option.type + '.' + _programAndOptions[@getLastValue(option.key)]
                #env.logger.info "_parameter " + JSON.stringify(_parameter,null,2)
                options.push _parameter
              else
                lastValue = @attributeValues[@getLastValue(option.key)]
                if _.isNumber(lastValue)
                  _value = Number lastValue
                else
                  _value = _.find(option.constraints.allowedvalues, (o)=> o.indexOf(@attributeValues[@getLastValue(option.key)]) >=0)
                options.push {key: option.key, value: _value}

            env.logger.info "@haid: " + @haid + ", _key: " + _key + ", options: " + JSON.stringify(options,null,2)

            if @haid? and _key? and options?
              #@plugin.homeconnect.setSelectedProgram(@haid, _key, options)
              #.then((appliances)=>
              #  setTimeout(()=>
              @plugin.homeconnect.setActiveProgram(@haid, _key, options)
              .then(()=>
                env.logger.debug "setActiveProgram executed"
                resolve()
              )
              .catch((err)=>
                env.logger.error "Error setActiveProgram " + err
                reject("Error setActiveProgram")
              )
              #  ,2000)
              #).catch((err)=>
              #  env.logger.debug "Error handled setProgram " + err
              #  reject("Error handled setProgram")
              #)
            else
              env.logger.debug "Invalid @haid, _key or options"
              reject("Invalid @haid, _key or options")
          when "stop"
            activeStates = ['DelayedStart','Run','Pause','ActionRequired']
            unless @attributeValues.OperationState in activeStates
              env.logger.debug "Stop not allowed for device '#{@haid}' when OperationState is '#{@attributeValues.OperationState}'"
              reject("Stop not allowed for device")
              return
            @plugin.homeconnect.stopActiveProgram(@haid)
            .then(()=>
              resolve()
            )
            .catch((err)=>
              env.logger.error "Error stopActiveProgram"
              reject("Error stopActiveProgram")
            )
          when "pause"
            unless _.find(@deviceAdapter.supportedCommands, (c) => (c.key).indexOf("BSH.Common.Command.PauseProgram")>=0)?
              env.logger.debug  "Pause not supported for device #{@haid}"
              reject("Pause not supported")
            activeStates = ['Run']
            if @attributeValues.OperationState in activeStates
              @plugin.homeconnect.setCommand(@haid,'BSH.Common.Command.PauseProgram')
              .then(()=>
                resolve()
              )
              .catch((err)=>
                env.logger.debug  "Handled Error setCommand PauseProgram: #{@haid} " + err.message
                reject("Error setCommand PauseProgram")
              )
            else
              env.logger.debug "Pause not allowed for device '#{@haid}' when OperationState is '#{@attributeValues.OperationState}'"
              reject("Pause not allowed")
          when "resume"
            unless _.find(@deviceAdapter.supportedCommands, (c) => (c.key).indexOf("BSH.Common.Command.ResumeProgram")>=0)?
              env.logger.debug  "Resume not supported for device #{@haid}"
              reject()
            activeStates = ['Pause']
            if @attributeValues.OperationState in activeStates
              @plugin.homeconnect.setCommand(@haid,"BSH.Common.Command.ResumeProgram")
              .then(()=>
                resolve()
              )
              .catch((err)=>
                env.logger.debug "Handled Error setCommand PauseProgram: #{@haid} - " + err.message
                reject("Error setCommand PauseProgram")
              )
            else
              env.logger.debug "Resume not allowed for device '#{@haid}' when OperationState is '#{@attributeValues.OperationState}'"
              reject("Resume not allowed")
          else
            env.logger.debug  "Invalid execute command: '#{command}'"
            reject("Invalid execute command")
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

      @program = null
      @options = null
      @programAndOptions = null

      setCommand = (command) =>
        @command = command

      programOptionString = (m,tokens) =>
        unless tokens?
          context?.addError("No variable")
          return
        @programAndOptions = tokens
        setCommand("startoptions")
        return

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
            return m.match(' startopts ')
              .matchVariable(programOptionString)
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
          actionHandler: new HomeconnectActionHandler(@framework, homeconnectDevice, @command, @programAndOptions)
        }
      else
        return null


  class HomeconnectActionHandler extends env.actions.ActionHandler

    constructor: (@framework, @homeconnectDevice, @command, @programAndOptions) ->

    executeAction: (simulate) =>
      if simulate
        return __("would have cleaned \"%s\"", "")
      else
        if @programAndOptions?
          _var = @programAndOptions.slice(1) if @programAndOptions.indexOf('$') >= 0
          _programAndOptions = @framework.variableManager.getVariableValue(_var)
          unless _programAndOptions?
            return __("\"%s\" Rule not executed, #{_var} is not a valid variable", "")
        else
          __programAndOptions = null
  
        @homeconnectDevice.execute(@homeconnectDevice, @command, _programAndOptions)
        .then(()=>
          return __("\"%s\" Rule executed", @command)
        ).catch((err)=>
          return __("\"%s\" Rule not executed: ", err)
        )


  homeconnectPlugin = new HomeconnectPlugin
  return homeconnectPlugin

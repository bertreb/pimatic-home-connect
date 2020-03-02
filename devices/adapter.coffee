module.exports = (env) ->
  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  events = require 'events'
  _ = require 'lodash'
  Oven = require('./oven')
  CoffeeMaker = require('./coffeemaker')

  class Adapter extends events.EventEmitter

    constructor: (haType) ->

      switch haType
        when "CoffeeMaker"
          @adapter = new CoffeeMaker()
          env.logger.info "Adapter0: " + JSON.stringify(@adapter,null,2)
        when "Oven"
          @adapter = new Oven()
        else
          env.logger.debug "Device type #{hatype} not yet supported"
          return

      # generic definitions
      @selectedProgram = "BSH.Common.Root.SelectedProgram"

      env.logger.info "@Adapter2: " + haType + ", " + JSON.stringify(@adapter,null,2)


      # ha specific definitions
      @programs = @adapter.programs
      @supportedOptions = @adapter.supportedOptions
      @supportedStatus = @adapter.supoortedStatus
      @powerOffState = @adapter.powerOffState

    getLastValue: (key) =>
      _keyArray = key.split(".")
      env.logger.info "KeyArray " + _keyArray
      return _keyArray[_keyArray.length-1]

    getOptions: () =>
      return @supportedOptions

    getStatus: () =>
      return @supportedStatus

    getProgramOrOption: (programOrOption) =>

      if @selectedProgram.indexOf(programOrOption.key)>=0
        resultProg =
          name: "program"
          value: @getLastValue(programOrOption.value)
        return resultProg

      prog = _.find(@programs, (p)=> (programOrOption.key).indexOf(p.name)>=0)
      if prog?
        resultProg =
          name: "program"
          value: @getLastValue(programOrOption.key)
        return resultProg

      opt = _.find(@supportedOptions, (o)=> (programOrOption.key).indexOf(o.key)>=0)
      if opt?
        resultOpt = 
          name: opt.name
        if opt.type is "string"
          resultOpt["value"] = @getLastValue(programOrOption.value)
        else
          resultOpt["value"] = Math.floor(Number programOrOption.value)
        return resultOpt

      stat = _.find(@supportedStatus, (s)=> (programOrOption.key).indexOf(s.key)>=0)
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

      if (programOrOption.key).startsWith("BSH.Common.Status.OperationState")
        resultOps = 
          name: "status"
          value: @getLastValue(programOrOption.value)
        return resultOps

      return null

    getPowerOffState: () =>
      return @powerOffState


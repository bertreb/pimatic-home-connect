module.exports = (env) ->

  @supportedTypes = ["CoffeeMaker","Oven"]

  class CoffeeMaker
    constructor: () ->
      @programs = [
        {name: "Cooking.Oven.Program.HeatingMode.PreHeating"},
        {name: "Cooking.Oven.Program.HeatingMode.HotAir"},
        {name: "Cooking.Oven.Program.HeatingMode.TopBottomHeating"},
        {name: "Cooking.Oven.Program.HeatingMode.PizzaSetting"},
        {name: "Cooking.Oven.Program.HeatingMode.HotAirEco"},
        {name: "Cooking.Oven.Program.HeatingMode.HotAirGrilling"},
        {name: "Cooking.Oven.Program.HeatingMode.TopBottomHeatingEco"},
        {name: "Cooking.Oven.Program.HeatingMode.BottomHeating"},
        {name: "Cooking.Oven.Program.HeatingMode.SlowCook"},
        {name: "Cooking.Oven.Program.HeatingMode.IntensiveHeat"},
        {name: "Cooking.Oven.Program.HeatingMode.KeepWarm"},
        {name: "Cooking.Oven.Program.HeatingMode.PreheatOvenware"},
        {name: "Cooking.Oven.Program.HeatingMode.FrozenHeatupSpecial"},
        {name: "Cooking.Oven.Program.HeatingMode.Desiccation"},
        {name: "Cooking.Oven.Program.HeatingMode.Defrost"},
        {name: "Cooking.Oven.Program.HeatingMode.Proof"}
      ]
      @selectedProgram = "BSH.Common.Root.SelectedProgram"
      @supportedOptions = [
        {
          name: "SetpointTemperature"
          type: "number"
          description: ""
          unit: "°C"
          default: 30
          key: "Cooking.Oven.Option.SetpointTemperature"
        },
        {
          name: "Duration"
          type: "number"
          description: "Duration in seconds"
          unit: "sec"
          default: 30
          key: "BSH.Common.Option.Duration"
        },
        {
          name: "FastPreHeat"
          type: "boolean"
          description: ""
          unit: "°C"
          default: false
          key: "Cooking.Oven.Option.FastPreHeat"
        }
      ]

      @supportedStatus = [
        {
          name: "CurrentCavityTemperature"
          type: "number"
          description: "CurrentCavityTemperature"
          unit: "°C"
          default: 0
          key: "Cooking.Oven.Status.CurrentCavityTemperature"
        },
        {
          name: "RemainingProgramTime"
          type: "number"
          description: ""
          unit: "sec"
          default: 0
          key: "BSH.Common.Option.RemainingProgramTime"
        },
        {
          name: "DoorState"
          type: "string"
          description: ""
          unit: ""
          default: "Closed"
          key: "BSH.Common.Status.DoorState"
        },
        {
          name: "RemoteControl"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "BSH.Common.Status.RemoteControlActive"
        },
        {
          name: "OperationState"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "BSH.Common.Status.OperationState"
        },
        {
          name: "RemoteControlStartAllowed"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "BSH.Common.Status.RemoteControlStartAllowed"
        }
      ]

  class Oven
    constructor: () ->
      @programs = [
        {name: "Cooking.Oven.Program.HeatingMode.PreHeating"},
        {name: "Cooking.Oven.Program.HeatingMode.HotAir"},
        {name: "Cooking.Oven.Program.HeatingMode.TopBottomHeating"},
        {name: "Cooking.Oven.Program.HeatingMode.PizzaSetting"},
        {name: "Cooking.Oven.Program.HeatingMode.HotAirEco"},
        {name: "Cooking.Oven.Program.HeatingMode.HotAirGrilling"},
        {name: "Cooking.Oven.Program.HeatingMode.TopBottomHeatingEco"},
        {name: "Cooking.Oven.Program.HeatingMode.BottomHeating"},
        {name: "Cooking.Oven.Program.HeatingMode.SlowCook"},
        {name: "Cooking.Oven.Program.HeatingMode.IntensiveHeat"},
        {name: "Cooking.Oven.Program.HeatingMode.KeepWarm"},
        {name: "Cooking.Oven.Program.HeatingMode.PreheatOvenware"},
        {name: "Cooking.Oven.Program.HeatingMode.FrozenHeatupSpecial"},
        {name: "Cooking.Oven.Program.HeatingMode.Desiccation"},
        {name: "Cooking.Oven.Program.HeatingMode.Defrost"},
        {name: "Cooking.Oven.Program.HeatingMode.Proof"}
      ]
      @selectedProgram = "BSH.Common.Root.SelectedProgram"
      @supportedOptions = [
        {
          name: "SetpointTemperature"
          type: "number"
          description: ""
          unit: "°C"
          default: 30
          key: "Cooking.Oven.Option.SetpointTemperature"
        },
        {
          name: "Duration"
          type: "number"
          description: "Duration in seconds"
          unit: "sec"
          default: 30
          key: "BSH.Common.Option.Duration"
        },
        {
          name: "FastPreHeat"
          type: "boolean"
          description: ""
          unit: "°C"
          default: false
          key: "Cooking.Oven.Option.FastPreHeat"
        }
      ]

      @supportedStatus = [
        {
          name: "CurrentCavityTemperature"
          type: "number"
          description: "CurrentCavityTemperature"
          unit: "°C"
          default: 0
          key: "Cooking.Oven.Status.CurrentCavityTemperature"
        },
        {
          name: "RemainingProgramTime"
          type: "number"
          description: ""
          unit: "sec"
          default: 0
          key: "BSH.Common.Option.RemainingProgramTime"
        },
        {
          name: "DoorState"
          type: "string"
          description: ""
          unit: ""
          default: "Closed"
          key: "BSH.Common.Status.DoorState"
        },
        {
          name: "RemoteControl"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "BSH.Common.Status.RemoteControlActive"
        },
        {
          name: "OperationState"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "BSH.Common.Status.OperationState"
        },
        {
          name: "RemoteControlStartAllowed"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "BSH.Common.Status.RemoteControlStartAllowed"
        }
      ]

  return exports = {
    CoffeeMaker
    Oven
  }

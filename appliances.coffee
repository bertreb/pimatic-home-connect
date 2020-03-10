module.exports = (env) ->

  class CoffeeMaker

    constructor: () ->
      @programs = [
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.Espresso"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.EspressoMacchiato"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.Coffee"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.Cappuccino"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.LatteMacchiato"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.CaffeLatte"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Americano"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.EspressoDoppio"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.FlatWhite"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Galao"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.MilkFroth"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.WarmMilk"},
        {name: "ConsumerProducts.CoffeeMaker.Program.Beverage.Ristretto"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Cortado"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.KleinerBrauner"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.GrosserBrauner"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Verlaengerter"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.VerlaengerterBraun"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.WienerMelange"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.FlatWhite"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Cortado"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.CafeCortado"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.CafeConLeche"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.CafeAuLait"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Doppio"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Kaapi"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.KoffieVerkeerd"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Galao"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Garoto"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.Americano"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.RedEye"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.BlackEye"},
        {name: "ConsumerProducts.CoffeeMaker.Program.CoffeeWorld.DeadEye"}
      ]

      @powerOffState = "BSH.Common.EnumType.PowerState.Standby"
      @selectedProgram = "BSH.Common.Root.SelectedProgram"
      @supportedOptions = [
        {
          name: "Temperature"
          type: "string"
          description: ""
          unit: "C"
          default: ""
          key: "ConsumerProducts.CoffeeMaker.Option.CoffeeTemperature"
        },
        {
          name: "FillQuantity"
          type: "number"
          description: ""
          unit: "ml"
          default: 0
          key: "ConsumerProducts.CoffeeMaker.Option.FillQuantity"
        },
        {
          name: "Strength"
          type: "string"
          description: ""
          unit: ""
          default: ""
          key: "ConsumerProducts.CoffeeMaker.Option.BeanAmount"
        }
      ]

      @supportedStatus = [
        {
          name: "DoorState"
          type: "string"
          description: ""
          unit: ""
          default: "Closed"
          key: "BSH.Common.Status.DoorState"
        },
        {
          name: "remoteStart"
          type: "string"
          description: ""
          unit: ""
          default: "true"
          key: "BSH.Common.Status.RemoteControlStartAllowed"
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
          name: "BeanContainerEmpty"
          type: "string"
          description: ""
          unit: ""
          default: "false"
          key: "ConsumerProducts.CoffeeMaker.Event.BeanContainerEmpty"
        },
        {
          name: "WaterTankEmpty"
          type: "string"
          description: ""
          unit: ""
          default: "false"
          key: "ConsumerProducts.CoffeeMaker.Event.WaterTankEmpty"
        },
        {
          name: "DripTrayFull"
          type: "string"
          description: ""
          unit: ""
          default: "false"
          key: "ConsumerProducts.CoffeeMaker.Event.DripTrayFull"
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
          name: "ElapsedProgramTime"
          type: "number"
          description: ""
          unit: "sec"
          default: 0
          key: "BSH.Common.Option.ElapsedProgramTime"
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

  class Washer
    constructor: () ->
      @programs = [
        {name: "LaundryCare.Washer.Program.Cotton"},
        {name: "LaundryCare.Washer.Program.EasyCare"},
        {name: "LaundryCare.Washer.Program.Mix"},
        {name: "LaundryCare.Washer.Program.DelicatesSilk"},
        {name: "LaundryCare.Washer.Program.Wool"},
        {name: "LaundryCare.Washer.Program.Sensitive"},
        {name: "LaundryCare.Washer.Program.Auto30"},
        {name: "LaundryCare.Washer.Program.Auto40"},
        {name: "LaundryCare.Washer.Program.Auto60"},
        {name: "LaundryCare.Washer.Program.Chiffon"},
        {name: "LaundryCare.Washer.Program.Curtains"},
        {name: "LaundryCare.Washer.Program.DarkWash"},
        {name: "LaundryCare.Washer.Program.Dessous"},
        {name: "LaundryCare.Washer.Program.Monsoon"},
        {name: "LaundryCare.Washer.Program.Outdoor"},
        {name: "LaundryCare.Washer.Program.PlushToy"},
        {name: "LaundryCare.Washer.Program.ShirtsBlouses"},
        {name: "LaundryCare.Washer.Program.Outdoor"},
        {name: "LaundryCare.Washer.Program.SportFitness"},
        {name: "LaundryCare.Washer.Program.Towels"},
        {name: "LaundryCare.Washer.Program.WaterProof"}
      ]
      @selectedProgram = "BSH.Common.Root.SelectedProgram"
      @supportedOptions = [
        {
          name: "RemainingProgramTime"
          type: "number"
          description: "RemainingProgramTime in seconds"
          unit: "sec"
          default: 0
          key: "BSH.Common.Option.RemainingProgramTime"
        },
        {
          name: "Temperature"
          type: "string"
          description: ""
          unit: "°C"
          default: ""
          key: "LaundryCare.Washer.Option.Temperature"
        },
        {
          name: "SpinSpeed"
          type: "string"
          description: "SpinSpeed in rpm"
          unit: "rpm"
          default: ""
          key: "LaundryCare.Washer.Option.SpinSpeed"
        },
        {
          name: "ProgramProgress"
          type: "string"
          description: "ProgramProgress in %"
          unit: "%"
          default: ""
          key: "BSH.Common.Option.ProgramProgress"
        }        
      ]

      @supportedStatus = [
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

  class Dishwasher
    constructor: () ->
      @programs = [
        {name: "Dishcare.Dishwasher.Program.Auto1"},
        {name: "Dishcare.Dishwasher.Program.Auto2"},
        {name: "Dishcare.Dishwasher.Program.Auto3"},
        {name: "Dishcare.Dishwasher.Program.Eco50"},
        {name: "Dishcare.Dishwasher.Program.Quick45"},
        {name: "Dishcare.Dishwasher.Program.Intensiv70"},
        {name: "Dishcare.Dishwasher.Program.Normal65"},
        {name: "Dishcare.Dishwasher.Program.Glas40"},
        {name: "Dishcare.Dishwasher.Program.GlassCare"},
        {name: "Dishcare.Dishwasher.Program.NightWash"},
        {name: "Dishcare.Dishwasher.Program.Quick65"},
        {name: "Dishcare.Dishwasher.Program.Normal45"},
        {name: "Dishcare.Dishwasher.Program.Intensiv45"},
        {name: "Dishcare.Dishwasher.Program.AutoHalfLoad"},
        {name: "Dishcare.Dishwasher.Program.IntensivPower"},
        {name: "Dishcare.Dishwasher.Program.MagicDaily"},
        {name: "Dishcare.Dishwasher.Program.Super60"},
        {name: "Dishcare.Dishwasher.Program.Kurz60"},
        {name: "Dishcare.Dishwasher.Program.ExpressSparkle65"},
        {name: "Dishcare.Dishwasher.Program.MachineCare"},
        {name: "Dishcare.Dishwasher.Program.SteamFresh"},
        {name: "Dishcare.Dishwasher.Program.MaximumCleaning"}
      ]
      @selectedProgram = "BSH.Common.Root.SelectedProgram"
      @supportedOptions = [
        {
          name: "RemainingProgramTime"
          type: "number"
          description: "RemainingProgramTime in seconds"
          unit: "sec"
          default: 0
          key: "BSH.Common.Option.RemainingProgramTime"
        },
        {
          name: "StartInRelative"
          type: "number"
          description: "delayed start in seconds"
          unit: "sec"
          default: 0
          key: "BSH.Common.Option.StartInRelative"
        }
      ]

      @supportedStatus = [
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
    Washer
    Dishwasher
  }

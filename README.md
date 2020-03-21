# pimatic-home-connect
Pimatic plugin for connecting Home-Connect devices to Pimatic

# Installation

### HOME-CONNECT
Create an application in your account on the [developers site of Home-connect](https://developer.home-connect.com).
For the simulator usage Authorisation Code Grant Flow as authorisation type and  http://localhost:3000/o2c as redirect uri. The ClientId and ClientSecret of this application must be used as clientIdSim and clientSecretSim in the plugin.
For live usage create another application and use Device Flow as authorisation type. The ClientId and ClientSecret of this application must be used as clientId and clientSecret in the plugin.

### PIMATIC
1. install the plugin via the plugins page
2. add your credentials; clientId and clientSecret (for live) and clientIdSim and clientSecretSim (for simulator)
3. set the plugin in simulator or live (simulator = false)
4. restart Pimatic
5. create a HomeconnectManager device
6. start discovery and add discovered devices

The devices CoffeeMaker, Washer, DishWasher, Oven, Dryer, FridgeFreezer, Hood and CleaningRobot are implemented. In simulator mode the approval of the Home-Connect access rights is handled by the plugin. No popup screen!
In Live mode the approval is done via the gui. In the HomeconnectManager device the link in the label is used for the authentication uri.

Devices must be added via the device discovery.
All devices are of the HomeconnectDevice class.

Switching from Simulator mode to Live mode is done in the plugin config. After that a restart is required. Simulator devices are offline in Live mode and Live devices are offline in Simulator mode.

## Actions
Actions can be executed via rules. The rule syntax is
```
homeconnect <device id or name> [start, startopts $<programOptionsVariable>, pause, resume, stop]
```
Whether an action is available, is depending on the device capabilities and the allowed control scope.

The format for the $\<programOptionsVariable\> is:
```
program: <programId>, <optionName>: <optionValue>, <optionName>: <optionValue>, ...
```

Example for CoffeeMaker

```
homeconnect <CoffeeMakerId> startopts $options
```
Value of the variable $options is
```
program: Cappuccino, BeanAmount: DoubleShot, CoffeeTemperature: 95C, FillQuantity: 100
```
The used syntax for the program name, option name and option value must be exactly as defined in the api documentation. See the Programs and options for syntax definitions. For an example see the CoffeeMaker [API-DOCS](https://developer.home-connect.com/docs/coffee-maker/supported_programs_and_options). For the name part after the last dot is used for the value its also the part after the last dots (in case of enum) or the value itself. If a program or option parameter is not used in the option variable, the current setting for that parameter is used.

For the interface with the Home-Connect api the homeconnect_api.js is used. This lib is written by Alexander Thoukydides.

# Programs and options
The following program and options settings are the maximum available for a device. A specific type / brand of a device will probably use a subset of these values. See your device manual to check what is available for your device.
### Coffeemaker
___Programs___: Espresso, EspressoMacchiato, Coffee, Cappuccino, LatteMacchiato, CaffeLatte, Americano, EspressoDoppio, FlatWhite, Galao, MilkFroth, WarmMilk, Ristretto, Cortado, KleinerBrauner, GrosserBrauner, Verlaengerter, VerlaengerterBraun, WienerMelange, FlatWhite, Cortado, CafeCortado, CafeConLeche, CafeAuLait, Doppio, Kaapi, KoffieVerkeerd, Galao, Garoto, Americano, RedEye, BlackEye, DeadEye

___BeanAmount___: VeryMild, Mild, MildPlus, Normal, NormalPlus, Strong, StrongPlus, VeryStrong, VeryStrongPlus, ExtraStrong, DoubleShot, DoubleShotPlus, DoubleShotPlusPlus, CoffeeGround

___CoffeeTemperature___: 88C, 90C, 92C, 94C, 95C, 96C

___FillQuantity___: 60 - 260 with stepsize 20

### Washer
___Programs___: Cotton, EasyCare, Mix, DelicatesSilk, Wool, Sensitive, Auto30, Auto40, Auto60, Chiffon, Curtains, DarkWash, Dessous, Monsoon, Outdoor, PlushToy, ShirtsBlouses, Outdoor, SportFitness, Towels, WaterProof

___Temperature___: Cold, GC20, GC30, GC40, GC50, GC60, GC70, GC80, GC90

___Spinspeed___: RPM400, RPM600, RPM800, RPM1000, RPM1200, RPM1400

### DishWasher
___Programs___: Auto1, Auto2, Auto3, Eco50, Quick45, Intensiv70, Normal65, Glas40, GlassCare, NightWash, Quick65, Normal45, Intensiv45, AutoHalfLoad, IntensivPower, MagicDaily, Super60, Kurz60, ExpressSparkle65, MachineCare, SteamFresh, MaximumCleaning

___StartInRelative___: 1 - 86340 (in seconds)

### Oven
___Programs___: PreHeating, HotAir, TopBottomHeating, PizzaSetting, HotAirEco, HotAirGrilling, TopBottomHeatingEco, BottomHeating, SlowCook, IntensiveHeat, KeepWarm, PreheatOvenware, FrozenHeatupSpecial, Desiccation, Defrost, Proof

___SetpointTemperature___: 30 - 275 (in °C)

___Duration___: 1 - 86340 (in seconds)

___FastPreHeat___: false or true

___StartInRelative___: 1 - 86340 (in seconds)

### Dryer
___Programs___: Cotton, Synthetic, Mix, Blankets, BusinessShirts, DownFeathers, Hygiene, Program.Jeans, Outdoor, SyntheticRefresh, Towels, Delicates, Super40, Shirts15, Pillow, AntiShrink

___DryingTarget___: IronDry, CupboardDry, CupboardDryPlus

### FridgeFreezer
___Programs___: none

___SetpointTemperatureRefrigerator___: 2 to 8 (in °C)

___SetpointTemperatureFreezer___: -24 to -16 (in °C)

___SuperModeRefrigerator___: false or true

___SuperModeFreezer___: false or true

___EcoMode___: false or true

### Hood
___Programs___: Automatic, Venting, DelayedShutOff

___VentingLevel___: FanOff, FanStage01, FanStage02, FanStage03, FanStage04, FanStage05

___IntensiveLevel___: IntensiveStageOff, IntensiveStage1, IntensiveStage2

### CleaningRobot
___Programs___: CleanAll, CleanMap, GoHome

___CleaningMode___: Silent, Standard, Power

___ReferenceMapID___: TempMap, Map1, Map2, Map3, Map4, Map5


---
$$The minimum requirement for this plugin is node v8!$$

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

The devices CoffeeMaker, Washer, DishWasher, Oven, Dryer and FridgeFreezer are implemented. In simulator mode the approval of the Home-Connect access rights is handled by the plugin. No popup screen!
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

The format for the $<programOptionsVariable> is:
program: <programId>, <optionname>: <optionValue>, <optionname>: <optionValue>, ...

Example for CoffeeMaker

```
homeconnect <CoffeeMakerId> startopts $options
```
Value of the variable $options is
```
program: Cappuccino, BeanAmount: DoubleShot, CoffeeTemperature: 95C, FillQuantity: 100
```
The used syntax for the program name, option name and option value must be exactly as defined in the api documentation. For example the CoffeeMaker [API-DOCS](https://developer.home-connect.com/docs/coffee-maker/supported_programs_and_options). For the name part after the last dot is used for the value its also the part after the last dots (in case of enum) or the value itself.

For the interface with the Home-Connect api the homeconnect_api.js is used. This lib is written by Alexander Thoukydides.

# Programs and options
The following program and options settings are the maximum available for a device. A secific type / brand of a device will use this values or a subset.
### Coffeemaker
**Programs**: Espresso, EspressoMacchiato, Coffee, Cappuccino, LatteMacchiato, CaffeLatte, Americano, EspressoDoppio, FlatWhite, Galao, MilkFroth, WarmMilk, Ristretto, Cortado, KleinerBrauner, GrosserBrauner, Verlaengerter, VerlaengerterBraun, WienerMelange, FlatWhite, Cortado, CafeCortado, CafeConLeche, CafeAuLait, Doppio, Kaapi, KoffieVerkeerd, Galao, Garoto, Americano, RedEye, BlackEye, DeadEye

**BeanAmount**: VeryMild, Mild, MildPlus, Normal, NormalPlus, Strong, StrongPlus, VeryStrong, VeryStrongPlus, ExtraStrong, DoubleShot

**DoubleShotPlus**, DoubleShotPlusPlus, CoffeeGround

**CoffeeTemperature**: 88C, 90C, 92C, 94C, 95C, 96C

**FillQuantity**: 60 - 260 with stepsize 20

---
**The minimum requirement for this plugin is node v8!**

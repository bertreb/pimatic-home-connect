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
All devices are of the HomeconnectDevice class. Simulator devices are disable in Live mode and Live devices are disables in simulator mode.

Switching from Simulator mode to Live mode is done in the plugin config. After that a restart is required. Simulator devices are offline in Live mode and Live devices are offline in Simulator mode.

## Actions
Actions can be executed via rules. The rule syntax is
```
homeconnect <device id or name> [start, pause, resume, stop]
```
Whether an action is available, is depending on the device capabilities and the allowed control scope.

For the interface with the Home-Connect api the homeconnect_api.js is used. This lib is written by Alexander Thoukydides.

---
**The minimum requirement for this plugin is node v8+!**

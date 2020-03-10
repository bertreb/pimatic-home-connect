# pimatic-home-connect
Pimatic plugin for connecting home-connect devices to Pimatic

Instructions for installing the proof-of-concept.

### HOME-CONNECT
Create an application in your account on the [developers site of Home-connect](https://developer.home-connect.com).
Use Authorisation Code Grant Flow as authorisation type and  http://localhost:3000/o2c as redirect uri.

### PIMATIC
0. stop pimatic
1. clone this repository in your node_modules (/home/pi/node_modules)
2. in the pimatic-home-connect directory run the command -> npm install
4. add the plugin to the config.json under "plugins"
5. restart pimatic and activate the plugin
6. create a HomeconnectManager device and add your clientIdSim and clientSecretSim credentials (only Sim works!)
7. start dicovering and adding simulator devices in the discovery

The CoffeeMaker, Washer, DishWasher and Oven are implemented in this poc.
Devices must be added via the device discovery.
All devices are of the HomeconnectDevice class.

This concept could change in the future, and is only for testing  with the simulator appliances. Due to the security concept in this poc, use it only in private LAN's!
Actions are not yet supported!

The interface with the Home-Connect api is based on the homeconnect_api.js written by Alexander Thoukydides.

---
**The minimum requirement for this plugin is for nodejs 8+!**

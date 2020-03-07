# pimatic-home-connect
Pimatic plugin for connecting home-connect devices to Pimatic

Instructions for installing the proof-of-concept.

### HOME-CONNECT
Create an application in your account on the [developers site of Home-connect](https://developer.home-connect.com)
Use Authorisation Code Grant Flow as authorisation type and  http://localhost:3000/o2c as redirect uri.

### PIMATIC
0. stop pimatic
1. clone this repository in your node_modules (/home/pi/node_modules)
2. in the pimatic-home-connect directory run the command -> npm install
3. copy the file main.js from the pimatic-home-connect directory to
   ./pimatic-home-connect/node_modules/home-connect-js (replace the file)
4. add in the plugin config your clientId and clientSecret
5. restart pimatic
6. an authorisation approval screen will popup

The CoffeeMaker and the Oven are implemented in this poc.
Devices must be added via the device discovery.
All devices are of the HomeconnectDevice class.

This concept will change in the future, and is only tested with the simulator appliances. Due to the security concept in this poc, use it only in private LAN's!
Actions are not yet supported!

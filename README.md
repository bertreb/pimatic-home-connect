# pimatic-home-connect
Pimatic plugin for connecting home-connect devices to Pimatic

Instructions for installing the proof-of-concept.

0. stop pimatic
1. clone this repository in your node_modules (/home/pi/node_modules)
2. copy the file main.js from the pimatic-home-connect directory to
   ./pimatic-home-connect/node_modules/home-connect-js (replace the file)
3. add in the plugin config your clientId and clientSecret
4. restart pimatic
5. an authorisation approval screen will popup

The CoffeeMaker and the Oven are implemented in this poc.
Device must be added via the device discovery.
This concept will change in the future, and is only tested with the simulator appliances. Due to the security concept in this poc, use it only in private LAN's!
Actions are not yet supported!

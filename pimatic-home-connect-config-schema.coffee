# #pimatic-home-connect configuration options
module.exports = {
  title: "pimatic-home-connect configuration options"
  type: "object"
  properties:
    clientId:
      descpription: "The home-connect clientid"
      type: "string"
    clientSecret:
      descpription: "The home-connect secret code"
      type: "string"
    simulation:
      description: "If enabled the plugin will use the simulated Homme Appliences"
      type: "boolean"
      default: true
    debug:
      description: "Debug mode. Writes debug messages to the pimatic log, if set to true."
      type: "boolean"
      default: false
}

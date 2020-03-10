module.exports = {
  title: "pimatic-home-connect device config schemas"
  HomeconnectManager: {
    title: "HomeconnectManager config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
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
      clientIdSim:
        descpription: "The home-connect simulator Grant Flow clientid"
        type: "string"
      clientSecretSim:
        descpription: "The home-connect simulator Grant Flow secret code"
        type: "string"
  }
  HomeconnectDevice: {
    title: "HomeconnectDevice config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties:{
      haid:
        description: "The haID of the appliance"
        type: "string"
      hatype:
        description: "The type of the appliance"
        type: "string"
      brand:
        description: "The brand of the appliance"
        type: "string"
      enumber:
        description: "The enumber of the appliance"
        type: "string"
      vib:
        description: "The Vertriebs Identifikations Bezeichner of the appliance"
        type: "string"
    }
  }
}

module.exports = {
  title: "pimatic-home-connect device config schemas"
  HomeconnectManager: {
    title: "HomeconnectManager config options"
    type: "object"
    extensions: ["xLink", "xAttributeOptions"]
    properties: {}
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
      simulated:
        descpription: "If the device is a simulated device"
        type: "boolean"
    }
  }
}

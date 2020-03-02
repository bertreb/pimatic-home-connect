module.exports = {
  title: "pimatic-home-connect device config schemas"
  HomeconnectDevice: {
    title: "CoffeeDevice config options"
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

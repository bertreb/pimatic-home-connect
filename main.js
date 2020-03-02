const EventSource = require('eventsource');
const utils = require('./lib/utils');
const fs = require('fs');

class HomeConnect {

    constructor(clientId, clientSecret) {
        this.clientId = clientId;
        this.clientSecret = clientSecret;
        this.eventSources = {};
    }

    init(options) {
        global.isSimulated = (options != undefined
            && 'isSimulated' in options
            && typeof options.isSimulated === 'boolean') ? options.isSimulated : false;

        if ('secret' in options) {this.secret = options.secret} else {this.secret = null}
        return new Promise((resolve, reject) => {
          if (fs.existsSync('tokens') && this.secret != null) {
              fs.readFile('tokens', (err,file)=> {
                if (err)
                  console.log('Error saving token ' + JSON.stringify(err))
                this.decrypt(file, this.secret)
                .then((d)=> {
                  this.tokens = JSON.parse(d); //JSON.stringify(data));
                  if ((this.tokens.timestamp+1000*this.tokens.expires_in-Date.now()) > 0) {
                    console.log("Access token exists and is still valid")
                    utils.getClient(this.tokens.access_token)
                    .then((client) => {
                      this.client = client
                      resolve()
                    })              
                  }
                  else 
                  {
                  return utils.authorize(this.clientId, this.clientSecret)
                  .then(tokens => {
                      this.tokens = tokens;
                      this.encryptSave(this.tokens, this.secret);
                      return utils.getClient(this.tokens.access_token);
                   })
                  .then(client => {
                      this.client = client;
                      resolve();
                  })
                  .catch(err => {
                      console.log('Error =====> ' + JSON.stringify(err))
                      reject(err)
                    });
                  }
                })
              })               
          } 
          else 
          {
              return utils.authorize(this.clientId, this.clientSecret)
              .then(tokens => {
                  this.tokens = tokens;
                  this.encryptSave(this.tokens, this.secret);
              })
              .then(client => {
                  this.client = client;
                  resolve();
              })
              .catch(err => {
                  console.log('Error =====> ' + JSON.stringify(err))
                  reject(err)
              });             
            }
        })
    }

    encryptSave(file,key) {
      return new Promise((resolve, reject) => {
        fs.writeFile('tokens', JSON.stringify(file), (err) => {
          if (err) {
            reject()
          }
          resolve()
        })
      })
    }

    decrypt(file, key) {
      return new Promise((resolve, reject) => {
          resolve(file);
      })
    }


    async command(tag, operationId, haid, body) {
        if (Date.now() > (this.tokens.timestamp + this.tokens.expires_in)) {
            this.tokens = await utils.refreshToken(this.clientSecret, this.tokens.refresh_token);
            this.encryptSave(this.tokens, this.secret)
            this.client = await utils.getClient(this.tokens.access_token);
        }
        return this.client.apis[tag][operationId]({ haid, body });
    }

    subscribe(haid, event, cb) {
        if (this.eventSources && !(haid in this.eventSources)) {
            let url = isSimulated ? urls.simulation.base : urls.physical.base;
            const es = new EventSource(url + 'api/homeappliances/' + haid + '/events', {
                headers: {
                    accept: 'text/event-stream',
                    authorization: 'Bearer ' + this.tokens.access_token
                }
            });

            this.eventSources = { ...this.eventSources, [haid]: es };
        }

        this.eventSources[haid].addEventListener(event, cb);
    }

    unsubscribe(haid, event, cb) {
        if (this.eventSources && haid in this.eventSources) {
            this.eventSources[haid].removeEventListener(event, cb);
        }
    }
}

module.exports = HomeConnect;
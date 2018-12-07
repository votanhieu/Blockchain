// Allows us to use ES6 in our migrations and tests.
require('babel-register')
var HDWalletProvider = require("truffle-hdwallet-provider");
var infura_apikey = "v3/1596fafaccac42e1983d0ff653fad7f2";
var mnemonic = "twelve words you can find in metamask/settings/reveal seed words blabla";
module.exports = {
  networks: {
    development: {
      host: 'localhost',
      port: 8545,
      network_id: '*' // Match any network id
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io/"+infura_apikey),
      network_id: 3,
      gas:   5000000,
      gasPrice:   650000000
    }
  }
}

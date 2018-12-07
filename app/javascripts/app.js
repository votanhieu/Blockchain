import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract'
import ipfs from './ipfs'

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:9545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }

  // App.start();
  ipfs.id(function(err, res) {
 if (err) throw err
 console.log("Connected to IPFS node!", res.id, res.agentVersion, res.protocolVersion);
 });
  createUser: function() {
 var username = $("#sign-up-username").val();
 var title = $("#sign-up-title").val();
 var intro = $("#sign-up-intro").val();
 var ipfsHash = ‘’;
console.log("Creating user on ipfs for", username);
var userJson = {
 username: username,
 title: title,
 intro: intro
 };
ipfs.add([Buffer.from(JSON.stringify(userJson))], function(err, res) {
 if (err) throw err
 ipfsHash = res[0].hash
console.log("creating user on eth for", username, title, intro, ipfsHash);
User.deployed().then(function(contractInstance) {
 // contractInstance.createUser(web3.fromAscii(username), web3.fromAscii(title), intro, ipfsHash, {gas: 2000000, from: web3.eth.accounts[0]}).then(function(index) {
 contractInstance.createUser(username, ipfsHash, {gas: 200000, from: web3.eth.accounts[0]}).then(function(success) {
 if(success) {
 console.log("created user on ethereum!");
 } else {
 console.log("error creating user on ethereum");
 }
 }).catch(function(e) {
 // There was an error! Handle it.
 console.log("error creating user:", username, ":", e);
 });
 
 });
 });
 
 }
 getAUser: function(instance, i) {
var instanceUsed = instance;
    var username;
    var ipfsHash;
    var address;
    var userCardId = 'user-card-' + i;
return instanceUsed.getUsernameByIndex.call(i).then(function(_username) {
console.log('username:', username = web3.toAscii(_username), i);
        
      $('#' + userCardId).find('.card-title').text(username);
    
      return instanceUsed.getIpfsHashByIndex.call(i);
}).then(function(_ipfsHash) {
console.log('ipfsHash:', ipfsHash = web3.toAscii(_ipfsHash), i);
// $('#' + userCardId).find('.card-subtitle').text('title');
if(ipfsHash != 'not-available') {
        var url = 'https://ipfs.io/ipfs/' + ipfsHash;
        console.log('getting user info from', url);
$.getJSON(url, function(userJson) {
console.log('got user info from ipfs', userJson);
          $('#' + userCardId).find('.card-subtitle').text(userJson.title);
          $('#' + userCardId).find('.card-text').text(userJson.intro);
});
      }
return instanceUsed.getAddressByIndex.call(i);
    
    }).then(function(_address) {
console.log('address:', address = _address, i);
      
      $('#' + userCardId).find('.card-eth-address').text(address);
return true;
}).catch(function(e) {
// There was an error! Handle it.
      console.log('error getting user #', i, ':', e);
});
}
});
var Bank = artifacts.require("./Bank.sol");
var User = artifacts.require("./User.sol");
module.exports = function(deployer) {
  deployer.deploy(Bank);
  deployer.deploy(User);
};
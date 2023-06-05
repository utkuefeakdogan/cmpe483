const MyLottery = artifacts.require("MyLottery");

module.exports = function (deployer) {
  deployer.deploy(MyLottery);
};
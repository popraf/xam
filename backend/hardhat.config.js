require('dotenv').config();
require("@nomicfoundation/hardhat-toolbox");
const { privateKey, polygonMumbaiRPC } = require('./.env.json');

module.exports = {
  solidity: "0.8.18",
  defaultNetwork: "localhost",

  networks: {
    hardhat: {},

    mumbai: {
      url: polygonMumbaiRPC,
      accounts: [privateKey],
      gasPrice: 35000000000,
    },

    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },

};

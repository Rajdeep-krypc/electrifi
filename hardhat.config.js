require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-verify");
require('dotenv').config()

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      
    },
    hederaTestNet: {
      url:"https://testnet.hashio.io/api",
      accounts: [process.env.PRIVATE_KEY],
      timeout: 60000,
    },
  },
  
  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 40000
  }
}

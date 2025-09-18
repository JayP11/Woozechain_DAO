require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); 

const {
  POLYGON_RPC,
  ETHEREUM_RPC,
  SEPOLIA_RPC,
  AMOY_RPC,
  TEST_ACCOUNT_PRIVATE_KEY,
  ACCOUNT_PRIVATE_KEY,
  POLYGONSCAN_API_KEY,
  ETHERSCAN_API_KEY,
} = require("./config");

module.exports = {
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        }
      }
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: POLYGON_RPC,
        blockNumber: 59462027,
      },
     
    },
    polygonAmoy: {
      url: AMOY_RPC,
      accounts: [TEST_ACCOUNT_PRIVATE_KEY],
      chainId: 80002,
      gas: "auto",
      gasPrice: 350000000000, // Adjust based on network conditions
      timeout: 600000, // 10 minutes
      pollingInterval: 5000,
    },
    sepolia: {
      url: SEPOLIA_RPC,
      accounts: [TEST_ACCOUNT_PRIVATE_KEY],
      chainId: 11155111,
      gas: "auto",
      gasPrice: "auto",
      timeout: 600000,
      pollingInterval: 5000,
    },
    polygon: {
      url: POLYGON_RPC,
      accounts: [ACCOUNT_PRIVATE_KEY],
      chainId: 137,
      gas: "auto",
      gasPrice: 350000000000, // Adjust based on network conditions
    },
    ethereum: {
      url: ETHEREUM_RPC,
      accounts: [ACCOUNT_PRIVATE_KEY],
      chainId: 1,
      gas: "auto",
      gasPrice: "auto",
    },
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      sepolia: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
      polygonAmoy: POLYGONSCAN_API_KEY,
    },
  },
};

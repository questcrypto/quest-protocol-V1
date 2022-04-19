require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const privateKeys = process.env.PRIVATE_KEYS || ""

module.exports = {
  networks: {
    development: {
      host: "127.0.1",
      port: 8545,
      network_id: "*",
    },
    ropsten: {
      provider: () => new HDWalletProvider(privateKeys.split(','), `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`),
      network_id: 3,       // Ropsten's id
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 5,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    bsc_testnet: {
      provider: () => new HDWalletProvider(privateKeys.split(','),`https://data-seed-prebsc-1-s1.binance.org:8545`),
      network_id: 97,
      skipDryRun: true
    } 
  },
  compilers: {
    solc: {
      version: "0.6.2", 
      settings: {
        optimizer: {
          enabled: true,
          runs: 1500
        }
      }
    }
  },

  db: {
    enabled: false
  }
}
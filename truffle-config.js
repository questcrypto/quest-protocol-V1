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
      gas: 5000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: 5000000000,
      skipDryRun: true     // Skip dry run before migrations? (default: false for public nets )
    },
    rinkeby: {
      provider: function() {
        return new HDWalletProvider(
          privateKeys.split(','), // Array of account private keys
          `https://rinkeby.infura.io/v3/${process.env.INFURA_ID}`// Url to an Ethereum Node
        )
      },
      gas: 10000000,
      gasPrice: 1500000000, // 5 gwei
      network_id: 4,
      skipDryRun: true
    },
    mumbai: {
      provider: () => new HDWalletProvider(privateKeys.split(','),`https://matic-mumbai.chainstacklabs.com`),
      network_id: 80001,
      gas: 5000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: 5000000000, //5 Gewi
      skipDryRun: true
    }, 
    polygon: {
      provider: () => new HDWalletProvider(privateKeys.split(','),`https://polygon-rpc.com/`),
      network_id: 137,
      gas: 6000000,        // Ropsten has a lower block limit than mainnet
      gasPrice: 35000000000,
      skipDryRun: true
    } 
  },
  compilers: {
    solc: {
      version: "0.8.10", 
      settings: {
        optimizer: {
          enabled: true,
          runs: 1500
        }
      }
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    bscscan: ""
  },
  db: {
    enabled: false
  }
}
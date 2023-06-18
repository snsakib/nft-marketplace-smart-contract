require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    testnet: {
      url: process.env.POLYGON_MUMBAI_TESTNET_URL,
      accounts: [`${process.env.ACCOUNTS_PRIVATE_KEY}`],
    },
    mainnet: {
      url: process.env.POLYGON_MAINNET_URL,
      accounts: [`${process.env.ACCOUNTS_PRIVATE_KEY}`],
    },
  },
};

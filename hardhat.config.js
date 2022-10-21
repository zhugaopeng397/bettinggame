require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});
/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
  solidity: "0.8.4",

  networks: {
    "optimism": {
       url: process.env.API_URL,
      //  accounts: [process.env.PRIVATE_KEY]
      accounts: { mnemonic: process.env.MNEMONIC }
    }
  },
  etherscan: {
    apiKey: process.env.OPTIMISMSCAN_API_KEY
  }

};

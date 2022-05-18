import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-web3";

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.3",
  compilers: {
    solc: {
      optimizer: {
        enabled: true,
        runs: 1000
      }
    }
  }
};
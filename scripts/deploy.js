
async function main() {
    // We get the contract to deploy
    const Contract = await ethers.getContractFactory("ByteAndCollect");
    const gameContract = await Contract.deploy();
  
    await gameContract.deployed();
  
    console.log("Contract deployed to: ", gameContract.address);

    let maxCellSize = 10
    let minCellCost = 10000000000
    let totalCell = maxCellSize * maxCellSize
    let totalDeposit = minCellCost * totalCell;

    await gameContract.deposit( {
        value: totalDeposit
    });
    console.log("Ether sent: ", totalDeposit);

    await gameContract.updateMinCellPrice(minCellCost);
    console.log("Min. cell price updated: ", minCellCost);

    await gameContract.updateMaxCellSize(maxCellSize);
    console.log("Max. cell size updated: ", maxCellSize);

    await gameContract.resetCellBalances();
    console.log("Cell balances reset");
    
    /*await web3.eth.sendTransaction({
        from: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
        to: "0xc07f279c6aCd79Fc63752aE917b052780B0Ca132",
        value: minCellCost,
      });
    */
    //0xc07f279c6aCd79Fc63752aE917b052780B0Ca132
  }
  
main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

/*
Start a local node : http://127.0.0.1:8545/

npx hardhat node

Open a new terminal and deploy the smart contract in the localhost network

npx hardhat run --network localhost scripts/deploy.js

As general rule, you can target any network configured in the hardhat.config.js

npx hardhat run --network <your-network> scripts/deploy.js
*/
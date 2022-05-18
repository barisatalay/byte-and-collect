
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

  }
  
main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});

/*
Start a local node

npx hardhat node

Open a new terminal and deploy the smart contract in the localhost network

npx hardhat run --network localhost scripts/deploy.js

As general rule, you can target any network configured in the hardhat.config.js

npx hardhat run --network <your-network> scripts/deploy.js
*/
import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract, BigNumber } from "ethers";
import { solidity } from "ethereum-waffle";

chai.use(solidity);

const minCellCost : BigNumber = BigNumber.from("10000000000000000");

describe('ByteAndCollect', ()=>{
    let gameContract: Contract;
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    beforeEach(async function () {
        let Contract = await ethers.getContractFactory('ByteAndCollect');
        
        [owner, user1, user2] = await ethers.getSigners();

        gameContract = await Contract.deploy();

        let maxCellSize = 10
        let totalCell = maxCellSize * maxCellSize
        let totalDeposit = minCellCost.mul(totalCell);

        await gameContract.deposit( {
            value: totalDeposit
        });
        await gameContract.updateMinCellPrice(minCellCost);
        await gameContract.updateMaxCellSize(maxCellSize);
        await gameContract.resetCellBalances();
    });

    describe('Deployment', () => {
        it("should deploy contracts", async() => {
            expect(gameContract).to.be.ok;
        })
        it('Should set the right owner', async () => {
            expect(await gameContract.owner()).to.equal(owner.address);
        });
        it('Should work all function', async () => {
            let maxCellSize = await gameContract.getMaxCellSize();
            
            let newPrice = await gameContract.getCellNewPrice(maxCellSize, maxCellSize);

            await gameContract.connect(user1).attackCell(maxCellSize, maxCellSize, {
                value: ethers.utils.parseEther("0.01")
            });

            let lastPrice = await gameContract.getCellLastPrice(maxCellSize, maxCellSize);
            expect(newPrice).to.eq(lastPrice);
        });
    });

    describe("Owner logics", ()=>{
        it("Should deposit ether", async () => {
            let depositBalance = await gameContract.getDepositBalance();
            //console.log("depositBalance: " + depositBalance);
            await gameContract.connect(owner).deposit( {
                value: 100
            });
            let newDepositBalance = await gameContract.getDepositBalance();
            //console.log("newDepositBalance: " + newDepositBalance);
            expect(newDepositBalance).to.not.eq(depositBalance);
            expect(newDepositBalance).to.be.eq(depositBalance.add(100));
        });

        it("Should widthdraw ether by owner wallet", async () => {
            let contractFirstBalance = await gameContract.getDepositBalance();
            let userFirstBalance = await owner.getBalance();
            
            await gameContract.connect(owner).withdraw();
            let contractBalance = await gameContract.getDepositBalance();
            let userBalance = await owner.getBalance();

            expect(contractFirstBalance).to.not.eq(0);
            expect(userFirstBalance).to.not.eq(0);
            expect(contractBalance).to.be.eq(0);
            expect(userBalance).to.not.eq(userFirstBalance);
        });
    });

    describe('Success Test', () => {
        it("First blood!", async() => {
            // console.log("1 eth price = " + ethers.utils.parseEther("1"));

            let newCellPrice = await gameContract.getCellNewPrice(1,1);
            
            await gameContract.connect(user1).attackCell(1,1, {
                value: ethers.utils.parseEther("0.011")
            });
            
            let newCellPrice1 = await gameContract.getCellNewPrice(1,1);
            let lastCellPrice1 = await gameContract.getCellLastPrice(1,1);
            
            expect(newCellPrice).to.eq(lastCellPrice1);

            await gameContract.connect(user2).attackCell(1,1, {
                value: newCellPrice1
            });

            let lastCellPrice2 = await gameContract.getCellLastPrice(1,1);
            
            expect(newCellPrice1).to.eq(lastCellPrice2);
        });

        it ("Should reset all cell data to min cell price", async () => {
            // Random cell    
            
            //let firstPrice = await gameContract.getCellLastPrice(5, 4);
            let newPrice = await gameContract.getCellNewPrice(5, 4);
            await gameContract.connect(user1).attackCell(5, 4, {
                value: newPrice
            });
            newPrice = await gameContract.getCellNewPrice(5, 4);
            await gameContract.connect(user2).attackCell(5, 4, {
                value: newPrice
            });

            let lastCellPrice = await gameContract.getCellLastPrice(5, 4);
            newPrice = await gameContract.getCellNewPrice(5, 4);

            await gameContract.resetCellBalances();
            let resetPrice = await gameContract.getCellLastPrice(5, 4);
            
            expect(resetPrice).to.not.eq(newPrice);
            expect(resetPrice).to.not.eq(lastCellPrice);
            expect(resetPrice).to.eq(ethers.utils.parseEther("0.01")); // Price of After reset
        });
    
        it("Should min cell price change", async () => {
            let firstMinCellPrice = await gameContract.getMinCellPrice();

            expect(firstMinCellPrice).to.be.eq(minCellCost);

            await gameContract.updateMinCellPrice(ethers.BigNumber.from("1000000000"));

            let newMinCellPrice = await gameContract.getMinCellPrice();

            expect(firstMinCellPrice).to.not.eq(newMinCellPrice);
            expect(newMinCellPrice).to.be.eq(ethers.BigNumber.from("1000000000"));

            await gameContract.updateMinCellPrice(minCellCost);
            newMinCellPrice = await gameContract.getMinCellPrice();

            expect(firstMinCellPrice).to.be.eq(newMinCellPrice);
        });

        it("Should max cell size change",async () => {
            let firstMaxCellSize = await gameContract.getMaxCellSize();
            await gameContract.updateMaxCellSize(20);
            let newMaxCellSize = await gameContract.getMaxCellSize();

            expect(firstMaxCellSize).to.not.eq(20);
            expect(newMaxCellSize).to.be.eq(20);
            
            await gameContract.updateMaxCellSize(firstMaxCellSize);
            newMaxCellSize = await gameContract.getMaxCellSize();
            expect(newMaxCellSize).to.be.eq(firstMaxCellSize);
        });

        /* 
        await expect(stakeContract.connect(user1).updateRewardPerSecond(poolRewardBanana.id, 0, updatedRewardPerSecond))
                .to.be
                .revertedWith('Ownable: caller is not the owner');
        */
    });

    describe('Fail Test', () => {
        it("Cell coordinate should not smaller 1", async() => {
            await expect(gameContract.connect(user1).attackCell(0,1))
                .to.be
                .revertedWith('Selected cell is not valid.');

            await expect(gameContract.connect(user1).attackCell(1,0))
                .to.be
                .revertedWith('Selected cell is not valid.');
        });

        it("Cell coordinate should not bigger than maxCellSize", async() => {
            let maxCellSize = await gameContract.getMaxCellSize();
            await expect(gameContract.connect(user1).attackCell(maxCellSize + 1, 1))
                .to.be
                .revertedWith('Selected cell is not valid.');

            await expect(gameContract.connect(user1).attackCell(1,maxCellSize + 1))
                .to.be
                .revertedWith('Selected cell is not valid.');
        });
    });
});
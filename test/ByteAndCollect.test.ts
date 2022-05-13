import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract, BigNumber } from "ethers";
import { Console } from "console";

const minCellCost = ethers.BigNumber.from("10000000000000000");

describe('ByteAndCollect', ()=>{
    let gameContract: Contract;
    let owner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;

    before(async function () {
        let Contract = await ethers.getContractFactory('ByteAndCollect');
        
        [owner, user1, user2] = await ethers.getSigners();

        gameContract = await Contract.deploy();

        await gameContract.updateMinCellPrice(minCellCost);

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
            
            await gameContract.connect(user1).attackCell(maxCellSize, maxCellSize, {
                value: ethers.utils.parseEther("0.01")
            });

            let newPrice = await gameContract.getCellNewPrice(maxCellSize, maxCellSize);
            let lastPrice = await gameContract.getCellLastPrice(maxCellSize, maxCellSize);
            expect(newPrice).to.not.eq(lastPrice);
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
        })

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
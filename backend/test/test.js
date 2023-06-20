const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("Deployment Test", function() {
    async function runEveryTime() {
        // Contract deployment
        const XamMechanicsConstract = await hre.ethers.getContractFactory("XamMechanics");
        const xamMechanics = await XamMechanicsConstract.deploy();
        // Get accounts
        const [owner, otherAccount, otherAccountTwo] = await ethers.getSigners();

        return { xamMechanics, owner, otherAccount, otherAccountTwo };
    }

    it("Deployment should assign the total supply of tokens to the owner", async function() {
        const { xamMechanics, owner, otherAccount } = await loadFixture(runEveryTime);
        const ownerBalance = await xamMechanics.balanceOf(owner.address);
        expect(await xamMechanics.totalSupply()).to.equal(ownerBalance);
    });

    it("Total supply should be equal to 1000 Ether", async function() {
        const { xamMechanics, owner } = await loadFixture(runEveryTime);
        const totalBalance = await xamMechanics.balanceOf(owner.address);
        expect(parseFloat(ethers.utils.formatEther(totalBalance))).to.equal(1000.0);
    });

    it("Transfer from owner to other account", async function() {
        const { xamMechanics, owner, otherAccount } = await loadFixture(runEveryTime);
        
        // Check initial balance of accounts
        const initOnwerBalance = await xamMechanics.balanceOf(owner.address);
        const initOtherAccountBalance = await xamMechanics.balanceOf(otherAccount.address);
        
        // Transfer 50 tokens
        await xamMechanics.transfer(otherAccount.address, ethers.utils.parseEther('50'));
        
        // Get balance after the transfer
        const endOnwerBalance = await xamMechanics.balanceOf(owner.address);
        const endOtherAccountBalance = await xamMechanics.balanceOf(otherAccount.address);

        expect(parseFloat(ethers.utils.formatEther(initOnwerBalance))).to.equal(1000.0);
        expect(parseFloat(ethers.utils.formatEther(initOtherAccountBalance))).to.equal(0.0);
        expect(parseFloat(ethers.utils.formatEther(endOnwerBalance))).to.equal(950.0);
        expect(parseFloat(ethers.utils.formatEther(endOtherAccountBalance))).to.equal(50.0);
    });

    it("Should emit Transfer events", async function() {
        const { xamMechanics, owner, otherAccount, otherAccountTwo } = await loadFixture(runEveryTime);
        
        // Transfer 50 tokens from owner to otherAccount
        await expect(xamMechanics.transfer(otherAccount.address, 50)).to.emit(xamMechanics, "Transfer").withArgs(owner.address, otherAccount.address, 50);
        
        // Transfer 50 tokens from addr1 to addr2, .connect(signer) is used to send a transaction from another account
        await expect(xamMechanics.connect(otherAccount).transfer(otherAccountTwo.address, 50)).to.emit(xamMechanics, "Transfer").withArgs(otherAccount.address, otherAccountTwo.address, 50);
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
        const { xamMechanics, owner, otherAccount, otherAccountTwo } = await loadFixture(runEveryTime);
        const initialOwnerBalance = await xamMechanics.balanceOf(owner.address);
  
        // Try to send 1 token from addr1 (0 tokens) to owner.
        // `require` will evaluate false and revert the transaction.
        await expect(xamMechanics.connect(otherAccount).transfer(owner.address, 1)).to.be.revertedWith("Not enough tokens");
  
        // Owner balance shouldn't have changed.
        expect(await xamMechanics.balanceOf(owner.address)).to.equal(initialOwnerBalance);
      });

});

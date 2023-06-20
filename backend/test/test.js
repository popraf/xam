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
        const [owner, otherAccount] = await ethers.getSigners();

        return { xamMechanics, owner, otherAccount };
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
        
        const initOnwerBalance = await xamMechanics.balanceOf(owner.address);
        const initOtherAccountBalance = await xamMechanics.balanceOf(otherAccount.address);

        await xamMechanics.transfer(otherAccount.address, ethers.utils.parseEther('50'));

        const endOnwerBalance = await xamMechanics.balanceOf(owner.address);
        const endOtherAccountBalance = await xamMechanics.balanceOf(otherAccount.address);

        expect(parseFloat(ethers.utils.formatEther(initOnwerBalance))).to.equal(1000.0);
        expect(parseFloat(ethers.utils.formatEther(initOtherAccountBalance))).to.equal(0.0);
        expect(parseFloat(ethers.utils.formatEther(endOnwerBalance))).to.equal(950.0);
        expect(parseFloat(ethers.utils.formatEther(endOtherAccountBalance))).to.equal(50.0);
    });

});

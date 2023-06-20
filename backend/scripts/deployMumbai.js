const hre = require("hardhat");
const fs = require('fs');

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log('Deploying contracts with the account:', deployer.address);
  
    const Contract = await ethers.getContractFactory('XamMechanics');
    const contract = await Contract.deploy();
  
    await contract.deployed();
  
    console.log('Contract deployed to:', contract.address);
  
    // Save contract address for later use
    fs.writeFileSync('contract-address.txt', contract.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });

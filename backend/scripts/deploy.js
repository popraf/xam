const hre = require("hardhat");

async function main() {
    console.log("Deploying Xam...");

    const XamMechanicsConstract = await hre.ethers.getContractFactory("XamMechanics");
    const xamMechanics = await XamMechanicsConstract.deploy();

    console.log(`XAM Contract address: ${xamMechanics.address}`);
}

main().catch((error) => {
    console.log(error);
    process.exitCode = 1;
});

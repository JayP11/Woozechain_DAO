const { ethers } = require('hardhat');
const saveToConfig = require('../utils/saveToConfig');
const { GOVERNANCE_FACTORY } = require('../config');

async function main() {
    console.log("Deploying TokenFactory");

    const TokenFactory = await ethers.getContractFactory("TokenFactory");
    const tokenFactory = await TokenFactory.deploy();
    await tokenFactory.waitForDeployment();

    const tokenFactoryAddress = await tokenFactory.getAddress();
    const tokenFactoryABI = (await artifacts.readArtifact('TokenFactory')).abi;

    await saveToConfig('TOKEN_FACTORY', 'ADDRESS', tokenFactoryAddress);
    await saveToConfig('TOKEN_FACTORY', 'ABI', tokenFactoryABI);

    console.log("TokenFactory deployed at:", tokenFactoryAddress);
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});

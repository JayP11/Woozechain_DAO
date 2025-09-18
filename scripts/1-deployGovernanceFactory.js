const { ethers } = require('hardhat');
const saveToConfig = require('../utils/saveToConfig');

async function main() {
    console.log("Deploying GovernanceFactory...");

    const GovernanceFactory = await ethers.getContractFactory("GovernanceFactory");
    const governanceFactory = await GovernanceFactory.deploy();
    await governanceFactory.waitForDeployment();

    const governanceFactoryAddress = await governanceFactory.getAddress();
    const governanceFactoryABI = (await artifacts.readArtifact('GovernanceFactory')).abi;

    await saveToConfig('GOVERNANCE_FACTORY', 'ADDRESS', governanceFactoryAddress);
    await saveToConfig('GOVERNANCE_FACTORY', 'ABI', governanceFactoryABI);

    console.log("GovernanceFactory deployed at:", governanceFactoryAddress);
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});

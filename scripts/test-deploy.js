const hre = require("hardhat");
const saveToConfig = require("../utils/saveToConfig");

async function deploy() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying USDC Custom Token Contract from:", deployer.address);

  const CustomToken = await hre.ethers.getContractFactory("CustomToken");
  const usdc = await CustomToken.deploy("Test Token", "TST", 100000000000, 6);

  // ✅ Wait for deployment transaction to be mined
  await usdc.waitForDeployment();

  await saveToConfig("TOKEN", "ADDRESS", await usdc.getAddress());
  console.log("TOKEN", await usdc.getAddress());
}

deploy().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

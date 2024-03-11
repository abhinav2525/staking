const hre = require("hardhat");

async function main() {

  const Staking = await hre.ethers.getContractFactory("Staking");
  const staking = await Staking.deploy('0x11bd4f78a0Cb724AF61A47ae7a27959e08dA3e2A','0x0005F28b015F76293f6cB1ECc1a41D31e0cF2117');

  await staking.deployed();

  console.log("staking deployed to:", staking.address);
}

// recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
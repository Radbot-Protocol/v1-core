import { network } from "hardhat";
import RadbotV1DeployerArtifact from "../artifacts/contracts/RadbotV1Deployer.sol/RadbotV1Deployer.json";

const { ethers } = await network.connect();

async function getInitCodeHash() {
  try {
    // Get the bytecode from the compiled artifact
    const bytecode = RadbotV1DeployerArtifact.bytecode;

    if (!bytecode) {
      throw new Error("Bytecode not found in artifact");
    }

    // Calculate the keccak256 hash of the bytecode
    const initCodeHash = ethers.keccak256(bytecode);

    console.log("=== RadbotV1Deployer Init Code Hash ===");
    console.log(`Init Code Hash: ${initCodeHash}`);
    console.log(`Init Code Hash (without 0x): ${initCodeHash.slice(2)}`);
    console.log(`Bytecode Length: ${bytecode.length} characters`);
    console.log(`Bytecode Length (bytes): ${(bytecode.length - 2) / 2} bytes`);

    // Also show the first and last few characters of the bytecode for verification
    console.log(`\nBytecode Preview:`);
    console.log(`First 50 chars: ${bytecode.slice(0, 50)}...`);
    console.log(`Last 50 chars: ...${bytecode.slice(-50)}`);

    return initCodeHash;
  } catch (error) {
    console.error("Error getting init code hash:", error);
    process.exit(1);
  }
}

// Run the script if called directly
getInitCodeHash()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

export { getInitCodeHash };

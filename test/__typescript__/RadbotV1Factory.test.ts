import { expect } from "chai";
import { network } from "hardhat";
import { stringToBytes32, stringToBytes16 } from "./helpers/string-helpers.js";

const { ethers } = await network.connect();

describe("RadbotV1Factory", function () {
  let factory: any;
  let syntheticFactory: any;
  let reservoirFactory: any;
  let stringHelper: any;
  let owner: any;
  let user1: any;
  let user2: any;
  let reserveToken0: any;
  let reserveToken1: any;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy StringHelper library first
    const StringHelper = await ethers.getContractFactory("StringHelper");
    stringHelper = await StringHelper.deploy();
    await stringHelper.waitForDeployment();

    // Deploy the synthetic factory
    const SyntheticFactory = await ethers.getContractFactory(
      "RadbotV1SyntheticFactory",
      {
        libraries: {
          StringHelper: await stringHelper.getAddress(),
        },
      }
    );
    syntheticFactory = await SyntheticFactory.deploy(owner.address);
    await syntheticFactory.waitForDeployment();

    // Deploy mock reserve tokens (USDC/USDT-like)
    const MockUSDC = await ethers.getContractFactory("MockUSDC");
    reserveToken0 = await MockUSDC.deploy();
    await reserveToken0.waitForDeployment();

    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    reserveToken1 = await MockUSDT.deploy();
    await reserveToken1.waitForDeployment();

    // Deploy the factory with library linking
    const Factory = await ethers.getContractFactory("RadbotV1Factory", {
      libraries: {
        StringHelper: await stringHelper.getAddress(),
      },
    });
    factory = await Factory.deploy();
    await factory.waitForDeployment();

    // Get the reservoir factory address from the factory
    reservoirFactory = await ethers.getContractAt(
      "RadbotV1ReservoirFactory",
      await factory.reservoirFactory()
    );
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await factory.owner()).to.equal(owner.address);
    });

    it("Should initialize with default fee amounts", async function () {
      expect(await factory.feeAmountTickSpacing(500)).to.equal(10);
      expect(await factory.feeAmountTickSpacing(3000)).to.equal(60);
      expect(await factory.feeAmountTickSpacing(10000)).to.equal(200);
    });
  });

  describe("create", function () {
    it("Should create a deployer successfully", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      const tx = await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );
      const receipt = await tx.wait();

      // Check that DeployerCreated event was emitted
      const event = receipt?.logs.find(
        (log: any) =>
          log.topics[0] ===
          factory.interface.getEvent("DeployerCreated").topicHash
      );
      expect(event).to.not.be.undefined;

      // Decode the event to check parameters
      const decodedEvent = factory.interface.parseLog(event!);
      expect(decodedEvent?.args.token0).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.token1).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.fee).to.equal(3000);
      expect(decodedEvent?.args.tickSpacing).to.equal(60);
      expect(decodedEvent?.args.deployer).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.reservoir).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.synthetic0).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.synthetic1).to.not.equal(ethers.ZeroAddress);
    });

    it("Should revert if tokens are the same", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };

      await expect(
        factory.create(
          tokenA,
          tokenA,
          3000,
          await reserveToken0.getAddress(),
          await reserveToken1.getAddress()
        )
      ).to.be.revertedWith("TA");
    });

    it("Should revert if fee is not enabled", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      await expect(
        factory.create(
          tokenA,
          tokenB,
          2500,
          await reserveToken0.getAddress(),
          await reserveToken1.getAddress()
        )
      ).to.be.revertedWith("TS");
    });

    it("Should revert if reserve token is zero address", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      await expect(
        factory.create(
          tokenA,
          tokenB,
          3000,
          ethers.ZeroAddress,
          await reserveToken1.getAddress()
        )
      ).to.be.revertedWith("TO");
    });

    it("Should create deployer with correct token ordering", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      const tx = await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );
      const receipt = await tx.wait();

      const event = receipt?.logs.find(
        (log: any) =>
          log.topics[0] ===
          factory.interface.getEvent("DeployerCreated").topicHash
      );
      expect(event).to.not.be.undefined;

      // Verify token ordering
      const decodedEvent = factory.interface.parseLog(event!);
      expect(BigInt(decodedEvent?.args.token0)).to.be.lt(
        BigInt(decodedEvent?.args.token1)
      );
    });
  });

  describe("getDeployer", function () {
    it("Should return zero address for non-existent deployer", async function () {
      // Create synthetic tokens first
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Get the synthetic token addresses from the factory's synthetic factory
      const factorySyntheticFactory = await ethers.getContractAt(
        "RadbotV1SyntheticFactory",
        await factory.syntheticFactory()
      );
      const syntheticAAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKA"),
        18
      );
      const syntheticBAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKB"),
        18
      );

      // Check for non-existent deployer with different fee
      const deployer = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        500
      );
      expect(deployer).to.equal(ethers.ZeroAddress);
    });

    it("Should return deployer address after creation", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Get the synthetic token addresses from the factory's synthetic factory
      const factorySyntheticFactory = await ethers.getContractAt(
        "RadbotV1SyntheticFactory",
        await factory.syntheticFactory()
      );
      const syntheticAAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKA"),
        18
      );
      const syntheticBAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKB"),
        18
      );

      const deployer = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        3000
      );
      expect(deployer).to.not.equal(ethers.ZeroAddress);
    });

    it("Should return same deployer for reverse token order", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Get the synthetic token addresses from the factory's synthetic factory
      const factorySyntheticFactory = await ethers.getContractAt(
        "RadbotV1SyntheticFactory",
        await factory.syntheticFactory()
      );
      const syntheticAAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKA"),
        18
      );
      const syntheticBAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKB"),
        18
      );

      const deployerAB = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        3000
      );

      const deployerBA = await factory.getDeployer(
        syntheticBAddress,
        syntheticAAddress,
        3000
      );

      expect(deployerAB).to.equal(deployerBA);
    });

    it("Should return different deployers for different fees", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      await factory.create(
        tokenA,
        tokenB,
        500,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Get the synthetic token addresses from the factory's synthetic factory
      const factorySyntheticFactory = await ethers.getContractAt(
        "RadbotV1SyntheticFactory",
        await factory.syntheticFactory()
      );
      const syntheticAAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKA"),
        18
      );
      const syntheticBAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKB"),
        18
      );

      const deployer3000 = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        3000
      );

      const deployer500 = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        500
      );

      expect(deployer3000).to.not.equal(deployer500);
    });
  });

  // Note: setOwner and enableFeeAmount functions are commented out in the contract
  // These tests are removed as the functions are not available

  describe("Edge Cases", function () {
    it("Should handle multiple fee tiers for same token pair", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      // Create deployers for different fee tiers
      await factory.create(
        tokenA,
        tokenB,
        500,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );
      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );
      await factory.create(
        tokenA,
        tokenB,
        10000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Get the synthetic token addresses from the factory's synthetic factory
      const factorySyntheticFactory = await ethers.getContractAt(
        "RadbotV1SyntheticFactory",
        await factory.syntheticFactory()
      );
      const syntheticAAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKA"),
        18
      );
      const syntheticBAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKB"),
        18
      );

      // Verify all deployers are different
      const deployer500 = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        500
      );
      const deployer3000 = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        3000
      );
      const deployer10000 = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        10000
      );

      expect(deployer500).to.not.equal(deployer3000);
      expect(deployer3000).to.not.equal(deployer10000);
      expect(deployer500).to.not.equal(deployer10000);
    });

    it("Should revert when trying to create deployer twice", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      // Create deployer first time
      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Try to create same deployer again
      await expect(
        factory.create(
          tokenA,
          tokenB,
          3000,
          await reserveToken0.getAddress(),
          await reserveToken1.getAddress()
        )
      ).to.be.revertedWith("DE");
    });

    it("Should handle token address ordering correctly", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      // Create tokens with specific addresses to test ordering
      await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );

      // Get the synthetic token addresses from the factory's synthetic factory
      const factorySyntheticFactory = await ethers.getContractAt(
        "RadbotV1SyntheticFactory",
        await factory.syntheticFactory()
      );
      const syntheticAAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKA"),
        18
      );
      const syntheticBAddress = await factorySyntheticFactory.getSynthetic(
        stringToBytes16("TKB"),
        18
      );

      const deployerAddress = await factory.getDeployer(
        syntheticAAddress,
        syntheticBAddress,
        3000
      );

      // Should be able to retrieve with reverse order
      const deployerAddressReverse = await factory.getDeployer(
        syntheticBAddress,
        syntheticAAddress,
        3000
      );

      expect(deployerAddress).to.equal(deployerAddressReverse);
    });

    it("Should emit correct events with proper parameters", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      const tx = await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );
      const receipt = await tx.wait();

      // Find the DeployerCreated event
      const event = receipt?.logs.find(
        (log: any) =>
          log.topics[0] ===
          factory.interface.getEvent("DeployerCreated").topicHash
      );

      expect(event).to.not.be.undefined;

      // Decode the event data to verify parameters
      const decodedEvent = factory.interface.parseLog(event!);

      // The contract sorts tokens by address, so token0 should be the smaller address
      expect(BigInt(decodedEvent?.args.token0)).to.be.lt(
        BigInt(decodedEvent?.args.token1)
      );
      expect(decodedEvent?.args.fee).to.equal(3000);
      expect(decodedEvent?.args.tickSpacing).to.equal(60);
      expect(decodedEvent?.args.deployer).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.reservoir).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.synthetic0).to.not.equal(ethers.ZeroAddress);
      expect(decodedEvent?.args.synthetic1).to.not.equal(ethers.ZeroAddress);
    });
  });

  describe("Gas Optimization", function () {
    it("Should have reasonable gas costs for deployer creation", async function () {
      const tokenA = {
        name: stringToBytes32("Token A"),
        symbol: stringToBytes16("TKA"),
        decimals: 18,
      };
      const tokenB = {
        name: stringToBytes32("Token B"),
        symbol: stringToBytes16("TKB"),
        decimals: 18,
      };

      const tx = await factory.create(
        tokenA,
        tokenB,
        3000,
        await reserveToken0.getAddress(),
        await reserveToken1.getAddress()
      );
      const receipt = await tx.wait();

      // Gas cost should be reasonable (adjust threshold as needed)
      expect(receipt?.gasUsed).to.be.lessThan(8000000); // 8M gas limit
    });
  });
});

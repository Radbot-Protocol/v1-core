import { expect } from "chai";
import { network } from "hardhat";
import { stringToBytes32, stringToBytes16 } from "./helpers/string-helpers.js";

const { ethers } = await network.connect();

describe("RadbotV1Factory", function () {
  let factory: any;
  let syntheticFactory: any;
  let stringHelper: any;
  let owner: any;
  let user1: any;
  let user2: any;
  let tokenA: any;
  let tokenB: any;

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
    syntheticFactory = await SyntheticFactory.deploy();
    await syntheticFactory.waitForDeployment();

    // Create synthetic tokens for testing
    await syntheticFactory.createSynthetic(
      stringToBytes32("Token A"),
      stringToBytes16("TKA"),
      18
    );
    const syntheticAAddress = await syntheticFactory.getSynthetic(
      stringToBytes16("TKA"),
      18
    );
    tokenA = await ethers.getContractAt("RadbotSynthetic", syntheticAAddress);

    await syntheticFactory.createSynthetic(
      stringToBytes32("Token B"),
      stringToBytes16("TKB"),
      18
    );
    const syntheticBAddress = await syntheticFactory.getSynthetic(
      stringToBytes16("TKB"),
      18
    );
    tokenB = await ethers.getContractAt("RadbotSynthetic", syntheticBAddress);

    // Initialize the synthetic tokens
    await tokenA.initialize(owner.address, ethers.parseEther("1000000"));
    await tokenB.initialize(owner.address, ethers.parseEther("1000000"));

    // Deploy the factory
    const Factory = await ethers.getContractFactory("RadbotV1Factory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();
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
      const tx = await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      const receipt = await tx.wait();

      // Check that DeployerCreated event was emitted
      const event = receipt?.logs.find(
        (log: any) =>
          log.topics[0] ===
          factory.interface.getEvent("DeployerCreated").topicHash
      );
      expect(event).to.not.be.undefined;

      // Check that deployer address is stored in mapping
      const deployerAddress = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      expect(deployerAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Should revert if tokens are the same", async function () {
      await expect(
        factory.create(
          await tokenA.getAddress(),
          await tokenA.getAddress(),
          3000
        )
      ).to.be.revertedWith("TA");
    });

    it("Should revert if fee is not enabled", async function () {
      await expect(
        factory.create(
          await tokenA.getAddress(),
          await tokenB.getAddress(),
          2500
        )
      ).to.be.revertedWith("TS");
    });

    it("Should revert if token0 is zero address", async function () {
      await expect(
        factory.create(ethers.ZeroAddress, await tokenB.getAddress(), 3000)
      ).to.be.revertedWith("TO");
    });

    it("Should create deployer with correct token ordering", async function () {
      // tokenA address should be less than tokenB address for proper ordering
      const tokenAAddr = await tokenA.getAddress();
      const tokenBAddr = await tokenB.getAddress();

      if (tokenAAddr < tokenBAddr) {
        const tx = await factory.create(tokenAAddr, tokenBAddr, 3000);
        const receipt = await tx.wait();

        const event = receipt?.logs.find(
          (log: any) =>
            log.topics[0] ===
            factory.interface.getEvent("DeployerCreated").topicHash
        );
        expect(event).to.not.be.undefined;
      }
    });
  });

  describe("getDeployer", function () {
    it("Should return zero address for non-existent deployer", async function () {
      const deployer = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      expect(deployer).to.equal(ethers.ZeroAddress);
    });

    it("Should return deployer address after creation", async function () {
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      const deployer = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      expect(deployer).to.not.equal(ethers.ZeroAddress);
    });

    it("Should return same deployer for reverse token order", async function () {
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      const deployerAB = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      const deployerBA = await factory.getDeployer(
        await tokenB.getAddress(),
        await tokenA.getAddress(),
        3000
      );

      expect(deployerAB).to.equal(deployerBA);
    });

    it("Should return different deployers for different fees", async function () {
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        500
      );

      const deployer3000 = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      const deployer500 = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        500
      );

      expect(deployer3000).to.not.equal(deployer500);
    });
  });

  describe("setOwner", function () {
    it("Should change owner successfully", async function () {
      await expect(factory.setOwner(user1.address))
        .to.emit(factory, "OwnerChanged")
        .withArgs(owner.address, user1.address);

      expect(await factory.owner()).to.equal(user1.address);
    });

    it("Should revert if not called by owner", async function () {
      await expect(
        factory.connect(user1).setOwner(user2.address)
      ).to.be.revertedWith("MO");
    });

    it("Should allow new owner to change owner again", async function () {
      // First change owner to user1
      await factory.setOwner(user1.address);
      expect(await factory.owner()).to.equal(user1.address);

      // Then user1 changes owner to user2
      await expect(factory.connect(user1).setOwner(user2.address))
        .to.emit(factory, "OwnerChanged")
        .withArgs(user1.address, user2.address);

      expect(await factory.owner()).to.equal(user2.address);
    });

    it("Should allow setting owner to zero address for permissionless mode", async function () {
      await expect(factory.setOwner(ethers.ZeroAddress))
        .to.emit(factory, "OwnerChanged")
        .withArgs(owner.address, ethers.ZeroAddress);

      expect(await factory.owner()).to.equal(ethers.ZeroAddress);
    });
  });

  describe("enableFeeAmount", function () {
    it("Should enable new fee amount successfully", async function () {
      await expect(factory.enableFeeAmount(2500, 50))
        .to.emit(factory, "FeeAmountEnabled")
        .withArgs(2500, 50);

      expect(await factory.feeAmountTickSpacing(2500)).to.equal(50);
    });

    it("Should revert if not called by owner", async function () {
      await expect(
        factory.connect(user1).enableFeeAmount(2500, 50)
      ).to.be.revertedWith("MO");
    });

    it("Should revert if fee is too high", async function () {
      await expect(factory.enableFeeAmount(1000000, 50)).to.be.revertedWith(
        "FE"
      );
    });

    it("Should revert if fee is already enabled", async function () {
      await expect(factory.enableFeeAmount(500, 10)).to.be.revertedWith("FE");
    });

    it("Should revert if tickSpacing is too high", async function () {
      await expect(factory.enableFeeAmount(2500, 16384)).to.be.revertedWith(
        "TS"
      );
    });

    it("Should revert if tickSpacing is zero", async function () {
      await expect(factory.enableFeeAmount(2500, 0)).to.be.revertedWith("TS");
    });

    it("Should allow creating deployer after enabling new fee", async function () {
      // Enable new fee
      await factory.enableFeeAmount(2500, 50);

      // Create deployer with new fee
      const tx = await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        2500
      );
      const receipt = await tx.wait();

      // Check that DeployerCreated event was emitted
      const event = receipt?.logs.find(
        (log: any) =>
          log.topics[0] ===
          factory.interface.getEvent("DeployerCreated").topicHash
      );
      expect(event).to.not.be.undefined;
    });
  });

  describe("Edge Cases", function () {
    it("Should handle multiple fee tiers for same token pair", async function () {
      // Create deployers for different fee tiers
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        500
      );
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        10000
      );

      // Verify all deployers are different
      const deployer500 = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        500
      );
      const deployer3000 = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      const deployer10000 = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        10000
      );

      expect(deployer500).to.not.equal(deployer3000);
      expect(deployer3000).to.not.equal(deployer10000);
      expect(deployer500).to.not.equal(deployer10000);
    });

    it("Should revert when trying to create deployer twice", async function () {
      // Create deployer first time
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      // Try to create same deployer again
      await expect(
        factory.create(
          await tokenA.getAddress(),
          await tokenB.getAddress(),
          3000
        )
      ).to.be.revertedWith("DE");
    });

    it("Should handle token address ordering correctly", async function () {
      // Create tokens with specific addresses to test ordering
      await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      const deployerAddress = await factory.getDeployer(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );

      // Should be able to retrieve with reverse order
      const deployerAddressReverse = await factory.getDeployer(
        await tokenB.getAddress(),
        await tokenA.getAddress(),
        3000
      );

      expect(deployerAddress).to.equal(deployerAddressReverse);
    });

    it("Should emit correct events with proper parameters", async function () {
      const tokenAAddr = await tokenA.getAddress();
      const tokenBAddr = await tokenB.getAddress();

      const tx = await factory.create(tokenAAddr, tokenBAddr, 3000);
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
      const expectedToken0 = tokenAAddr < tokenBAddr ? tokenAAddr : tokenBAddr;
      const expectedToken1 = tokenAAddr < tokenBAddr ? tokenBAddr : tokenAAddr;

      expect(decodedEvent?.args.token0).to.equal(expectedToken0);
      expect(decodedEvent?.args.token1).to.equal(expectedToken1);
      expect(decodedEvent?.args.fee).to.equal(3000);
      expect(decodedEvent?.args.tickSpacing).to.equal(60);
    });
  });

  describe("Gas Optimization", function () {
    it("Should have reasonable gas costs for deployer creation", async function () {
      const tx = await factory.create(
        await tokenA.getAddress(),
        await tokenB.getAddress(),
        3000
      );
      const receipt = await tx.wait();

      // Gas cost should be reasonable (adjust threshold as needed)
      expect(receipt?.gasUsed).to.be.lessThan(5000000); // 5M gas limit
    });
  });
});

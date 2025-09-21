import { expect } from "chai";
import { network } from "hardhat";
import { stringToBytes32, stringToBytes16 } from "./helpers/string-helpers.js";

const { ethers } = await network.connect();

describe("RadbotV1Deployer", function () {
  let factory: any;
  let syntheticFactory: any;
  let stringHelper: any;
  let deployer: any;
  let mockCallback: any;
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

    // Deploy the factory
    const Factory = await ethers.getContractFactory("RadbotV1Factory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();

    // Create a deployer using the factory
    await factory.create(
      await tokenA.getAddress(),
      await tokenB.getAddress(),
      3000
    );

    // Get the deployer address using the factory's getDeployer function
    const deployerAddress = await factory.getDeployer(
      await tokenA.getAddress(),
      await tokenB.getAddress(),
      3000
    );

    deployer = await ethers.getContractAt("RadbotV1Deployer", deployerAddress);

    // Initialize the synthetic tokens with the deployer as the minter
    await tokenA.initialize(deployerAddress, ethers.parseEther("1000000"));
    await tokenB.initialize(deployerAddress, ethers.parseEther("1000000"));

    // Deploy mock callback contract
    const MockCallbackFactory = await ethers.getContractFactory(
      "MockCallbackContract"
    );
    mockCallback = await MockCallbackFactory.deploy(deployerAddress);
    await mockCallback.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should have correct factory address", async function () {
      expect(await deployer.factory()).to.equal(await factory.getAddress());
    });

    it("Should have correct token addresses", async function () {
      const tokenAAddr = await tokenA.getAddress();
      const tokenBAddr = await tokenB.getAddress();

      // Tokens are sorted by address
      const expectedToken0 = tokenAAddr < tokenBAddr ? tokenAAddr : tokenBAddr;
      const expectedToken1 = tokenAAddr < tokenBAddr ? tokenBAddr : tokenAAddr;

      expect(await deployer.token0()).to.equal(expectedToken0);
      expect(await deployer.token1()).to.equal(expectedToken1);
    });

    it("Should have correct fee and tick spacing", async function () {
      expect(await deployer.fee()).to.equal(3000);
      expect(await deployer.tickSpacing()).to.equal(60);
    });

    it("Should start with zero liquidity", async function () {
      expect(await deployer.liquidity()).to.equal(0);
    });

    it("Should be in unlocked state initially", async function () {
      const slot0 = await deployer.slot0();
      expect(slot0.unlocked).to.be.false; // Starts locked until initialized
    });
  });

  describe("Initialization", function () {
    it("Should initialize successfully with valid sqrtPriceX96", async function () {
      // Calculate a valid sqrtPriceX96 value (1:1 ratio)
      const sqrtPriceX96 = "79228162514264337593543950336"; // sqrt(1) * 2^96

      await expect(deployer.initialize(sqrtPriceX96))
        .to.emit(deployer, "Initialize")
        .withArgs(sqrtPriceX96, 0); // tick should be 0 for 1:1 ratio

      const slot0 = await deployer.slot0();
      expect(slot0.sqrtPriceX96).to.equal(sqrtPriceX96);
      expect(slot0.tick).to.equal(0);
      expect(slot0.unlocked).to.be.true;
    });

    it("Should revert if already initialized", async function () {
      const sqrtPriceX96 = "79228162514264337593543950336";

      // Initialize once
      await deployer.initialize(sqrtPriceX96);

      // Try to initialize again
      await expect(deployer.initialize(sqrtPriceX96)).to.be.revertedWith("AI");
    });

    it("Should revert if sqrtPriceX96 is zero", async function () {
      await expect(deployer.initialize(0)).to.be.revertedWith("R");
    });

    it("Should revert if sqrtPriceX96 is too high", async function () {
      const tooHighSqrtPrice =
        "1461446703485210103287273052203988822378723970342"; // Max uint160
      await expect(deployer.initialize(tooHighSqrtPrice)).to.be.revertedWith(
        "R"
      );
    });
  });

  describe("Position Management", function () {
    beforeEach(async function () {
      // Initialize the deployer
      const sqrtPriceX96 = "79228162514264337593543950336";
      await deployer.initialize(sqrtPriceX96);
    });

    it("Should allow minting liquidity", async function () {
      const tickLower = -60;
      const tickUpper = 60;
      const amount = ethers.parseEther("1000");

      // Use the mock callback contract's helper function to avoid delegate call issues
      const tx = await mockCallback.mintLiquidity(
        await mockCallback.getAddress(),
        tickLower,
        tickUpper,
        amount,
        "0x"
      );

      await expect(tx).to.emit(deployer, "Mint");
    });
  });

  describe("Oracle Functions", function () {
    beforeEach(async function () {
      const sqrtPriceX96 = "79228162514264337593543950336";
      await deployer.initialize(sqrtPriceX96);
    });

    it("Should observe price correctly", async function () {
      // Increase observation cardinality first
      await deployer.increaseObservationCardinalityNext(10);

      // Advance time to create some observations
      await ethers.provider.send("evm_increaseTime", [60]);
      await ethers.provider.send("evm_mine");

      const secondsAgos = [0, 30, 60]; // Last minute

      // Call observe directly from the test, not through the mock callback
      // since this is a view function and doesn't need callback logic
      const [tickCumulatives, secondsPerLiquidityCumulativeX128s] =
        await deployer.observe(secondsAgos);

      expect(tickCumulatives.length).to.equal(3);
      expect(secondsPerLiquidityCumulativeX128s.length).to.equal(3);
    });

    it("Should snapshot cumulatives inside range", async function () {
      const tickLower = -60;
      const tickUpper = 60;

      // First mint some liquidity to make the range active
      await mockCallback.mintLiquidity(
        await mockCallback.getAddress(),
        tickLower,
        tickUpper,
        ethers.parseEther("1000"),
        "0x"
      );

      // Call snapshotCumulativesInside directly since it's a view function
      const [
        tickCumulativeInside,
        secondsPerLiquidityInsideX128,
        secondsInside,
      ] = await deployer.snapshotCumulativesInside(tickLower, tickUpper);

      expect(typeof tickCumulativeInside).to.equal("bigint");
      expect(typeof secondsPerLiquidityInsideX128).to.equal("bigint");
      expect(typeof secondsInside).to.equal("bigint");
    });
  });

  describe("Access Control", function () {
    it("Should only allow factory owner to set fee protocol", async function () {
      const sqrtPriceX96 = "79228162514264337593543950336";
      await deployer.initialize(sqrtPriceX96);

      // Get the factory owner (should be the deployer of the factory)
      const factoryOwner = owner; // Assuming owner deployed the factory

      // Only factory owner can set fee protocol
      await expect(deployer.connect(factoryOwner).setFeeProtocol(4, 4))
        .to.emit(deployer, "SetFeeProtocol")
        .withArgs(0, 0, 4, 4);

      // Non-owner should not be able to set fee protocol
      await expect(
        deployer.connect(user1).setFeeProtocol(4, 4)
      ).to.be.revertedWith("O");
    });
  });

  describe("Edge Cases", function () {
    beforeEach(async function () {
      const sqrtPriceX96 = "79228162514264337593543950336";
      await deployer.initialize(sqrtPriceX96);
    });

    it("Should handle zero amount minting", async function () {
      const tickLower = -60;
      const tickUpper = 60;

      await expect(
        mockCallback.mintLiquidity(
          await mockCallback.getAddress(),
          tickLower,
          tickUpper,
          0,
          "0x"
        )
      ).to.be.revertedWith("IA");
    });

    it("Should handle invalid tick ranges", async function () {
      const invalidTickLower = 60;
      const invalidTickUpper = -60;
      const amount = ethers.parseEther("1000");

      await expect(
        mockCallback.mintLiquidity(
          await mockCallback.getAddress(),
          invalidTickLower,
          invalidTickUpper,
          amount,
          "0x"
        )
      ).to.be.revertedWith("TLU");
    });

    it("Should handle ticks outside valid range", async function () {
      const tooLowTick = -887273; // One below MIN_TICK (-887272)
      const tooHighTick = 887272;
      const amount = ethers.parseEther("1000");

      await expect(
        mockCallback.mintLiquidity(
          await mockCallback.getAddress(),
          tooLowTick,
          tooHighTick,
          amount,
          "0x"
        )
      ).to.be.revertedWith("TLM");
    });
  });

  describe("Gas Optimization", function () {
    it("Should have reasonable gas costs for initialization", async function () {
      const tx = await deployer.initialize("79228162514264337593543950336");
      const receipt = await tx.wait();

      expect(receipt?.gasUsed).to.be.lessThan(200000); // 200K gas limit
    });

    it("Should have reasonable gas costs for minting", async function () {
      // Initialize the deployer first
      await deployer.initialize("79228162514264337593543950336");

      const tx = await mockCallback.mintLiquidity(
        await mockCallback.getAddress(),
        -60,
        60,
        ethers.parseEther("1000"),
        "0x"
      );
      const receipt = await tx.wait();

      expect(receipt?.gasUsed).to.be.lessThan(500000); // 500K gas limit
    });
  });
});

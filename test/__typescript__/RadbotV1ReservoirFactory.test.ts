import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

describe("RadbotV1ReservoirFactory", function () {
  let factory: any;
  let mockUSDC: any;
  let mockUSDT: any;
  let owner: any;
  let user1: any;
  let user2: any;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy mock tokens
    const MockUSDC = await ethers.getContractFactory("MockUSDC");
    mockUSDC = await MockUSDC.deploy();
    await mockUSDC.waitForDeployment();

    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    mockUSDT = await MockUSDT.deploy();
    await mockUSDT.waitForDeployment();

    // Deploy factory
    const Factory = await ethers.getContractFactory("RadbotV1ReservoirFactory");
    factory = await Factory.deploy();
    await factory.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await factory.owner()).to.equal(owner.address);
    });

    it("Should initialize with zero address for reservoir", async function () {
      expect(await factory.reservoir()).to.equal(ethers.ZeroAddress);
    });

    it("Should initialize with empty parameters", async function () {
      const params = await factory.parameters();
      expect(params.factory).to.equal(ethers.ZeroAddress);
      expect(params.token0).to.equal(ethers.ZeroAddress);
      expect(params.token1).to.equal(ethers.ZeroAddress);
      expect(params.epochDuration).to.equal(0);
      expect(params.maxWithdrawPerEpoch0).to.equal(0);
      expect(params.maxWithdrawPerEpoch1).to.equal(0);
      expect(params.maxWithdrawPerEpochR).to.equal(0);
      expect(params.upperLimit0).to.equal(0);
      expect(params.upperLimit1).to.equal(0);
      expect(params.upperLimitR).to.equal(0);
    });
  });

  describe("createReservoir", function () {
    it("Should create a reservoir with USDC and USDT", async function () {
      const tx = await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );

      const receipt = await tx.wait();
      const reservoirAddress = await factory.reservoir();

      expect(reservoirAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Should create a reservoir with USDT and USDC (reversed order)", async function () {
      const tx = await factory.createReservoir(
        await mockUSDT.getAddress(),
        await mockUSDC.getAddress()
      );

      const reservoirAddress = await factory.reservoir();
      expect(reservoirAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Should set correct parameters during creation", async function () {
      // Parameters are set during creation but cleared after
      // We need to check them during the transaction
      const tx = await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );

      // Parameters are cleared after creation, so we check they were set correctly
      // by verifying the reservoir was created with correct values
      const reservoirAddress = await factory.reservoir();
      const reservoir = await ethers.getContractAt(
        "RadbotV1Reservoir",
        reservoirAddress
      );

      expect(await reservoir.factory()).to.equal(await factory.getAddress());
      expect(await reservoir.token0()).to.equal(await mockUSDC.getAddress());
      expect(await reservoir.token1()).to.equal(await mockUSDT.getAddress());
      expect(await reservoir.epochDuration()).to.equal(1 * 24 * 60 * 60); // 1 day in seconds
      expect(await reservoir.maxWithdrawPerEpoch0()).to.equal(2500 * 10 ** 6);
      expect(await reservoir.maxWithdrawPerEpoch1()).to.equal(2500 * 10 ** 6);
      expect(await reservoir.maxWithdrawPerEpochR()).to.equal(5000 * 10 ** 6);
      expect(await reservoir.upperLimit0()).to.equal(1500);
      expect(await reservoir.upperLimit1()).to.equal(1500);
      expect(await reservoir.upperLimitR()).to.equal(3000);
    });

    it("Should clear parameters after creation", async function () {
      await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );

      // Parameters should be cleared after creation
      const params = await factory.parameters();
      expect(params.factory).to.equal(ethers.ZeroAddress);
      expect(params.token0).to.equal(ethers.ZeroAddress);
      expect(params.token1).to.equal(ethers.ZeroAddress);
    });

    it("Should revert when token0 equals token1", async function () {
      await expect(
        factory.createReservoir(
          await mockUSDC.getAddress(),
          await mockUSDC.getAddress()
        )
      ).to.be.revertedWith("TA");
    });

    it("Should revert when token0 is zero address", async function () {
      await expect(
        factory.createReservoir(ethers.ZeroAddress, await mockUSDT.getAddress())
      ).to.be.revertedWith("TO");
    });

    it("Should revert when token1 is zero address", async function () {
      await expect(
        factory.createReservoir(await mockUSDC.getAddress(), ethers.ZeroAddress)
      ).to.be.revertedWith("TO");
    });

    it("Should only allow creating reservoir once", async function () {
      // Create first reservoir
      await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );
      const firstReservoir = await factory.reservoir();

      // Try to create second reservoir (this should fail)
      await expect(
        factory.createReservoir(
          await mockUSDT.getAddress(),
          await mockUSDC.getAddress()
        )
      ).to.be.revertedWith("L");

      // The factory should still have the first reservoir
      const currentReservoir = await factory.reservoir();
      expect(currentReservoir).to.equal(firstReservoir);
      expect(currentReservoir).to.not.equal(ethers.ZeroAddress);
    });

    it("Should only allow owner to create reservoir", async function () {
      // Non-owner should not be able to create reservoir
      await expect(
        factory
          .connect(user1)
          .createReservoir(
            await mockUSDC.getAddress(),
            await mockUSDT.getAddress()
          )
      ).to.be.revertedWith("O");

      // Reservoir should still be zero address
      const reservoirAddress = await factory.reservoir();
      expect(reservoirAddress).to.equal(ethers.ZeroAddress);
    });

    it("Should prevent creating reservoir after lock is set", async function () {
      // Create first reservoir (this sets the lock)
      await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );

      const reservoirAddress = await factory.reservoir();
      expect(reservoirAddress).to.not.equal(ethers.ZeroAddress);

      // Try to create another reservoir (should fail due to lock)
      await expect(
        factory.createReservoir(
          await mockUSDT.getAddress(),
          await mockUSDC.getAddress()
        )
      ).to.be.revertedWith("L");

      // Verify the original reservoir is still there
      const currentReservoir = await factory.reservoir();
      expect(currentReservoir).to.equal(reservoirAddress);
    });
  });

  describe("Reservoir Integration", function () {
    let reservoir: any;

    beforeEach(async function () {
      await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );
      const reservoirAddress = await factory.reservoir();
      reservoir = await ethers.getContractAt(
        "RadbotV1Reservoir",
        reservoirAddress
      );
    });

    it("Should create a valid RadbotV1Reservoir contract", async function () {
      const code = await ethers.provider.getCode(await reservoir.getAddress());
      expect(code).to.not.equal("0x");
    });

    it("Should set correct owner in reservoir", async function () {
      // The reservoir owner is set to msg.sender (the factory address) during creation
      expect(await reservoir.owner()).to.equal(await factory.getAddress());
    });

    it("Should set correct factory in reservoir", async function () {
      expect(await reservoir.factory()).to.equal(await factory.getAddress());
    });

    it("Should set correct tokens in reservoir", async function () {
      expect(await reservoir.token0()).to.equal(await mockUSDC.getAddress());
      expect(await reservoir.token1()).to.equal(await mockUSDT.getAddress());
    });

    it("Should set correct epoch duration in reservoir", async function () {
      expect(await reservoir.epochDuration()).to.equal(1 * 24 * 60 * 60); // 1 day
    });

    it("Should set correct withdrawal limits in reservoir", async function () {
      expect(await reservoir.maxWithdrawPerEpoch0()).to.equal(2500 * 10 ** 6);
      expect(await reservoir.maxWithdrawPerEpoch1()).to.equal(2500 * 10 ** 6);
      expect(await reservoir.maxWithdrawPerEpochR()).to.equal(5000 * 10 ** 6);
    });

    it("Should set correct upper limits in reservoir", async function () {
      expect(await reservoir.upperLimit0()).to.equal(1500);
      expect(await reservoir.upperLimit1()).to.equal(1500);
      expect(await reservoir.upperLimitR()).to.equal(3000);
    });

    it("Should have zero balances initially", async function () {
      expect(await reservoir.balance0()).to.equal(0);
      expect(await reservoir.balance1()).to.equal(0);
    });

    it("Should allow owner to withdraw tokens", async function () {
      // First, transfer some tokens to the reservoir
      await mockUSDC.transfer(await reservoir.getAddress(), 1000 * 10 ** 6);
      await mockUSDT.transfer(await reservoir.getAddress(), 1000 * 10 ** 6);

      // Check balances
      expect(await reservoir.balance0()).to.equal(1000 * 10 ** 6);
      expect(await reservoir.balance1()).to.equal(1000 * 10 ** 6);

      // The factory owner can withdraw tokens (reservoir owner is factory address)
      // We need to call through the factory owner
      await reservoir.connect(owner).withdraw0(user1.address, 100 * 10 ** 6);
      await reservoir.connect(owner).withdraw1(user2.address, 100 * 10 ** 6);

      // Check balances after withdrawal
      expect(await mockUSDC.balanceOf(user1.address)).to.equal(100 * 10 ** 6);
      expect(await mockUSDT.balanceOf(user2.address)).to.equal(100 * 10 ** 6);
    });

    it("Should revert when non-owner tries to withdraw", async function () {
      // Transfer tokens to reservoir
      await mockUSDC.transfer(await reservoir.getAddress(), 1000 * 10 ** 6);

      // Non-owner should not be able to withdraw
      await expect(
        reservoir.connect(user1).withdraw0(user1.address, 100 * 10 ** 6)
      ).to.be.revertedWith("O");
    });

    it("Should enforce withdrawal limits", async function () {
      // Transfer tokens to reservoir
      await mockUSDC.transfer(await reservoir.getAddress(), 10000 * 10 ** 6);

      // Try to withdraw more than the limit
      await expect(
        reservoir.connect(owner).withdraw0(user1.address, 3000 * 10 ** 6)
      ).to.be.revertedWith("WLE");
    });

    it("Should enforce once per epoch withdrawal", async function () {
      // Transfer tokens to reservoir
      await mockUSDC.transfer(await reservoir.getAddress(), 1000 * 10 ** 6);

      // First withdrawal should succeed
      await reservoir.connect(owner).withdraw0(user1.address, 100 * 10 ** 6);

      // Second withdrawal in same epoch should fail with "LE" (Last Executed)
      await expect(
        reservoir.connect(owner).withdraw0(user1.address, 100 * 10 ** 6)
      ).to.be.revertedWith("LE");
    });
  });

  describe("Edge Cases", function () {
    it("Should handle different token orders correctly", async function () {
      // Create reservoir with USDT first, USDC second
      await factory.createReservoir(
        await mockUSDT.getAddress(),
        await mockUSDC.getAddress()
      );

      const reservoirAddress = await factory.reservoir();
      const reservoir = await ethers.getContractAt(
        "RadbotV1Reservoir",
        reservoirAddress
      );

      expect(await reservoir.token0()).to.equal(await mockUSDT.getAddress());
      expect(await reservoir.token1()).to.equal(await mockUSDC.getAddress());
    });

    it("Should create different reservoirs for different token pairs", async function () {
      // Create first reservoir
      await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );
      const reservoir1Address = await factory.reservoir();

      // Deploy a new factory for second reservoir
      const Factory2 = await ethers.getContractFactory(
        "RadbotV1ReservoirFactory"
      );
      const factory2 = await Factory2.deploy();
      await factory2.waitForDeployment();

      await factory2.createReservoir(
        await mockUSDT.getAddress(),
        await mockUSDC.getAddress()
      );
      const reservoir2Address = await factory2.reservoir();

      expect(reservoir1Address).to.not.equal(reservoir2Address);
    });
  });

  describe("Factory State Management", function () {
    it("Should maintain state correctly after creation", async function () {
      // Create first reservoir
      await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );

      const reservoirAddress = await factory.reservoir();
      expect(reservoirAddress).to.not.equal(ethers.ZeroAddress);

      // The factory should not allow creating multiple reservoirs
      // Second creation should fail
      await expect(
        factory.createReservoir(
          await mockUSDT.getAddress(),
          await mockUSDC.getAddress()
        )
      ).to.be.revertedWith("L");

      // The factory should still have the original reservoir
      const currentReservoirAddress = await factory.reservoir();
      expect(currentReservoirAddress).to.equal(reservoirAddress);
      expect(currentReservoirAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Should emit events if any", async function () {
      // Check if any events are emitted during reservoir creation
      const tx = await factory.createReservoir(
        await mockUSDC.getAddress(),
        await mockUSDT.getAddress()
      );

      const receipt = await tx.wait();
      // Note: The factory doesn't seem to emit events based on the contract code
      // but we can verify the transaction was successful
      expect(receipt.status).to.equal(1);
    });
  });
});

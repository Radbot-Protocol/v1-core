import { expect } from "chai";
import { network } from "hardhat";
import { stringToBytes32, stringToBytes16 } from "./helpers/string-helpers.js";

const { ethers } = await network.connect();

describe("RadbotV1SyntheticFactory", function () {
  let factory: any;
  let owner: any;
  let user1: any;
  let user2: any;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy StringHelper library first
    const StringHelper = await ethers.getContractFactory("StringHelper");
    const stringHelper = await StringHelper.deploy();
    await stringHelper.waitForDeployment();

    // Deploy factory with library linking
    const Factory = await ethers.getContractFactory(
      "RadbotV1SyntheticFactory",
      {
        libraries: {
          StringHelper: await stringHelper.getAddress(),
        },
      }
    );
    factory = await Factory.deploy(owner.address);
    await factory.waitForDeployment();
  });

  describe("Deployment", function () {
    it("Should set the correct owner", async function () {
      expect(await factory.owner()).to.equal(owner.address);
    });

    it("Should initialize with empty synthetic mapping", async function () {
      expect(
        await factory.getSynthetic(stringToBytes16("NONEXISTENT"), 18)
      ).to.equal(ethers.ZeroAddress);
    });
  });

  describe("createSynthetic", function () {
    it("Should create a synthetic token with 18 decimals", async function () {
      const token = {
        name: stringToBytes32("Test Token"),
        symbol: stringToBytes16("TEST"),
        decimals: 18,
      };
      const tx = await factory.createSynthetic(token);

      const receipt = await tx.wait();
      const syntheticAddress = await factory.getSynthetic(
        stringToBytes16("TEST"),
        18
      );

      expect(syntheticAddress).to.not.equal(ethers.ZeroAddress);
      expect(await factory.getSynthetic(stringToBytes16("TEST"), 18)).to.equal(
        syntheticAddress
      );
    });

    it("Should create a synthetic token with 6 decimals", async function () {
      const token = {
        name: stringToBytes32("USDC Token"),
        symbol: stringToBytes16("USDC"),
        decimals: 6,
      };
      const tx = await factory.createSynthetic(token);

      const syntheticAddress = await factory.getSynthetic(
        stringToBytes16("USDC"),
        6
      );

      expect(syntheticAddress).to.not.equal(ethers.ZeroAddress);
      expect(await factory.getSynthetic(stringToBytes16("USDC"), 6)).to.equal(
        syntheticAddress
      );
    });

    it("Should allow different symbols with same decimals", async function () {
      const token1 = {
        name: stringToBytes32("Token One"),
        symbol: stringToBytes16("TOK1"),
        decimals: 18,
      };
      await factory.createSynthetic(token1);

      const token2 = {
        name: stringToBytes32("Token Two"),
        symbol: stringToBytes16("TOK2"),
        decimals: 18,
      };
      await factory.createSynthetic(token2);

      const token1Address = await factory.getSynthetic(
        stringToBytes16("TOK1"),
        18
      );
      const token2Address = await factory.getSynthetic(
        stringToBytes16("TOK2"),
        18
      );

      expect(token1Address).to.not.equal(token2Address);
      expect(token1Address).to.not.equal(ethers.ZeroAddress);
      expect(token2Address).to.not.equal(ethers.ZeroAddress);
    });

    it("Should allow same symbol with different decimals", async function () {
      const token18 = {
        name: stringToBytes32("Token 18"),
        symbol: stringToBytes16("TOK"),
        decimals: 18,
      };
      await factory.createSynthetic(token18);

      const token6 = {
        name: stringToBytes32("Token 6"),
        symbol: stringToBytes16("TOK"),
        decimals: 6,
      };
      await factory.createSynthetic(token6);

      const token18Address = await factory.getSynthetic(
        stringToBytes16("TOK"),
        18
      );
      const token6Address = await factory.getSynthetic(
        stringToBytes16("TOK"),
        6
      );

      expect(token18Address).to.not.equal(token6Address);
      expect(token18Address).to.not.equal(ethers.ZeroAddress);
      expect(token6Address).to.not.equal(ethers.ZeroAddress);
    });

    it("Should revert when creating token with invalid decimals (not 6 or 18)", async function () {
      const token = {
        name: stringToBytes32("Invalid Token"),
        symbol: stringToBytes16("INV"),
        decimals: 8,
      };
      await expect(factory.createSynthetic(token)).to.be.revertedWith("CS");
    });

    it("Should revert when creating token with invalid decimals (0)", async function () {
      const token = {
        name: stringToBytes32("Invalid Token"),
        symbol: stringToBytes16("INV"),
        decimals: 0,
      };
      await expect(factory.createSynthetic(token)).to.be.revertedWith("CS");
    });

    it("Should revert when creating token with invalid decimals (9)", async function () {
      const token = {
        name: stringToBytes32("Invalid Token"),
        symbol: stringToBytes16("INV"),
        decimals: 9,
      };
      await expect(factory.createSynthetic(token)).to.be.revertedWith("CS");
    });

    it("Should allow any user to create synthetic tokens", async function () {
      const token = {
        name: stringToBytes32("User Token"),
        symbol: stringToBytes16("USER"),
        decimals: 18,
      };
      const tx = await factory.connect(user1).createSynthetic(token);

      const syntheticAddress = await factory.getSynthetic(
        stringToBytes16("USER"),
        18
      );
      expect(syntheticAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Should emit SyntheticCreated event", async function () {
      const token = {
        name: stringToBytes32("Event Token"),
        symbol: stringToBytes16("EVENT"),
        decimals: 18,
      };
      await expect(factory.createSynthetic(token)).to.emit(
        factory,
        "SyntheticCreated"
      );
    });
  });

  describe("getSynthetic", function () {
    beforeEach(async function () {
      const token = {
        name: stringToBytes32("Test Token"),
        symbol: stringToBytes16("TEST"),
        decimals: 18,
      };
      await factory.createSynthetic(token);
    });

    it("Should return correct address for existing synthetic", async function () {
      const syntheticAddress = await factory.getSynthetic(
        stringToBytes16("TEST"),
        18
      );
      expect(syntheticAddress).to.not.equal(ethers.ZeroAddress);
    });

    it("Should return zero address for non-existent synthetic", async function () {
      expect(
        await factory.getSynthetic(stringToBytes16("NONEXISTENT"), 18)
      ).to.equal(ethers.ZeroAddress);
    });

    it("Should return zero address for wrong decimals", async function () {
      expect(await factory.getSynthetic(stringToBytes16("TEST"), 6)).to.equal(
        ethers.ZeroAddress
      );
    });
  });

  describe("Edge Cases", function () {
    it("Should revert when creating token with empty name", async function () {
      const token = {
        name: stringToBytes32(""),
        symbol: stringToBytes16("SYMBOL"),
        decimals: 18,
      };
      await expect(factory.createSynthetic(token)).to.be.revertedWith("CN");
    });

    it("Should revert when creating token with empty symbol", async function () {
      const token = {
        name: stringToBytes32("Token Name"),
        symbol: stringToBytes16(""),
        decimals: 18,
      };
      await expect(factory.createSynthetic(token)).to.be.revertedWith("CSY");
    });

    it("Should handle maximum length symbols", async function () {
      const maxSymbol = "1234567890123456"; // 16 characters
      const token = {
        name: stringToBytes32("Max Symbol Token"),
        symbol: stringToBytes16(maxSymbol),
        decimals: 18,
      };
      const tx = await factory.createSynthetic(token);

      const syntheticAddress = await factory.getSynthetic(
        stringToBytes16(maxSymbol),
        18
      );
      expect(syntheticAddress).to.not.equal(ethers.ZeroAddress);
    });
  });

  describe("Integration with RadbotSynthetic", function () {
    it("Should create a valid RadbotSynthetic contract", async function () {
      const token = {
        name: stringToBytes32("Integration Test"),
        symbol: stringToBytes16("INT"),
        decimals: 18,
      };
      const tx = await factory.createSynthetic(token);

      const syntheticAddress = await factory.getSynthetic(
        stringToBytes16("INT"),
        18
      );

      // Verify it's a contract
      const code = await ethers.provider.getCode(syntheticAddress);
      expect(code).to.not.equal("0x");

      // Try to interact with the synthetic token
      const syntheticContract = await ethers.getContractAt(
        "RadbotSynthetic",
        syntheticAddress
      );
      expect(await syntheticContract.owner()).to.equal(owner.address);
    });
  });
});

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IRadbotV1Factory.sol";
import "./NoDelegateCall.sol";
import "./RadbotV1Launcher.sol";

import "./interfaces/synthetic/IRadbotV1SyntheticFactory.sol";
import "./interfaces/IRadbotV1ReservoirFactory.sol";
import "./interfaces/IRadbotSynthetic.sol";
import "./RadbotV1ReservoirFactory.sol";
import "./RadbotV1SyntheticFactory.sol";

contract RadbotV1Factory is IRadbotV1Factory, RadbotV1Launcher, NoDelegateCall {
    /// @inheritdoc IRadbotV1Factory
    address public override owner;

    address public immutable override syntheticFactory;
    address public immutable override reservoirFactory;

    /// @inheritdoc IRadbotV1Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IRadbotV1Factory
    mapping(address => mapping(address => mapping(uint24 => address)))
        public
        override getDeployer;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);

        syntheticFactory = address(new RadbotV1SyntheticFactory(msg.sender));
        reservoirFactory = address(new RadbotV1ReservoirFactory(msg.sender));
    }

    /// @inheritdoc IRadbotV1Factory
    function create(
        SyntheticToken calldata tokenA,
        SyntheticToken calldata tokenB,
        uint24 fee,
        address reserve0,
        address reserve1
    ) external override noDelegateCall returns (address deployer) {
        address sTokenA = IRadbotV1SyntheticFactory(syntheticFactory)
            .createSynthetic(tokenA);

        address sTokenB = IRadbotV1SyntheticFactory(syntheticFactory)
            .createSynthetic(tokenB);

        require(sTokenA != sTokenB, "TA");
        (address token0, address token1) = sTokenA < sTokenB
            ? (sTokenA, sTokenB)
            : (sTokenB, sTokenA);
        require(token0 != address(0), "TO");
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0, "TS");
        require(getDeployer[token0][token1][fee] == address(0), "DE");
        deployer = launch(address(this), token0, token1, fee, tickSpacing);
        getDeployer[token0][token1][fee] = deployer;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getDeployer[token1][token0][fee] = deployer;

        // Check if reservoir already exists, create if not
        address reservoir = IRadbotV1ReservoirFactory(reservoirFactory)
            .reservoir(reserve0, reserve1, deployer);
        if (reservoir == address(0)) {
            reservoir = IRadbotV1ReservoirFactory(reservoirFactory)
                .createReservoir(reserve0, reserve1, deployer);
        }

        emit DeployerCreated(
            token0,
            token1,
            fee,
            tickSpacing,
            deployer,
            reservoir,
            sTokenA,
            sTokenB
        );
    }
}

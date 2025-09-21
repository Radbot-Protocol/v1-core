// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./interfaces/IRadbotV1Factory.sol";
import "./NoDelegateCall.sol";
import "./RadbotV1Launcher.sol";

contract RadbotV1Factory is IRadbotV1Factory, RadbotV1Launcher, NoDelegateCall {
    /// @inheritdoc IRadbotV1Factory
    address public override owner;

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
    }

    /// @inheritdoc IRadbotV1Factory
    function create(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address deployer) {
        require(tokenA != tokenB, "TA");
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "TO");
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0, "TS");
        require(getDeployer[token0][token1][fee] == address(0), "DE");
        deployer = launch(address(this), token0, token1, fee, tickSpacing);
        getDeployer[token0][token1][fee] = deployer;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getDeployer[token1][token0][fee] = deployer;
        emit DeployerCreated(token0, token1, fee, tickSpacing, deployer);
    }

    /// @inheritdoc IRadbotV1Factory
    function setOwner(address _owner) external override {
        require(msg.sender == owner, "MO");
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IRadbotV1Factory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner, "MO");
        require(fee < 1000000, "FE");
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384, "TS");
        require(feeAmountTickSpacing[fee] == 0, "FE");

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}

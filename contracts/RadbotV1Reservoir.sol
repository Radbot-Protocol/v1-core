// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IRadbotReservoir.sol";

import "./extensions/ReserveLocked.sol";

import "./interfaces/IRadbotV1ReservoirFactory.sol";

import "./libraries/TransferHelper.sol";

contract RadbotV1Reservoir is IRadbotReservoir, ReserveLocked {
    bytes32 public constant WITHDRAW_KEY0 = keccak256("WITHDRAW0");
    bytes32 public constant WITHDRAW_KEY1 = keccak256("WITHDRAW1");

    uint8 private _lock = 0;

    address public override deployer;

    modifier onlyFactoryOwner() {
        require(msg.sender == IRadbotV1ReservoirFactory(factory).owner(), "O");
        _;
    }

    modifier lock() {
        require(_lock == 2, "L");
        _;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "D");
        _;
    }

    constructor() {
        owner = msg.sender;

        (
            factory,
            token0,
            token1,
            epochDuration,
            maxWithdrawPerEpoch0,
            maxWithdrawPerEpoch1,
            maxWithdrawPerEpochR,
            upperLimit0,
            upperLimit1,
            upperLimitR
        ) = IRadbotV1ReservoirFactory(msg.sender).parameters();
    }

    function initialize(address deployer_) external onlyFactoryOwner {
        require(_lock == 1, "L");
        _lock = 2;
        deployer = deployer_;
    }

    function balance0() public view override returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function balance1() public view override returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }

    /// @inheritdoc IRadbotReservoirActions
    /// @dev will be implemented in the future v1 focuses on radbot
    function reserve0() external override {}

    /// @inheritdoc IRadbotReservoirActions
    /// @dev will be implemented in the future v1 focuses on radbot
    function reserve1() external override {}

    /// @inheritdoc IRadbotReservoirOwnerActions
    function withdraw0(
        address to,
        uint256 amount
    )
        external
        override
        onlyFactoryOwner
        onlyOncePerEpoch(WITHDRAW_KEY0)
        withdrawToken0WithinEpochLimit(amount)
    {
        require(to != address(0), "TO");
        require(amount > 0, "IA");

        uint256 balanceBefore = IERC20(token0).balanceOf(to);

        TransferHelper.safeTransfer(token0, to, amount);

        require(IERC20(token0).balanceOf(to) > balanceBefore, "TF");
    }

    /// @inheritdoc IRadbotReservoirOwnerActions
    function withdraw1(
        address to,
        uint256 amount
    )
        external
        override
        onlyFactoryOwner
        onlyOncePerEpoch(WITHDRAW_KEY1)
        withdrawToken1WithinEpochLimit(amount)
    {
        require(to != address(0), "TO");
        require(amount > 0, "IA");

        uint256 balanceBefore = IERC20(token1).balanceOf(to);

        TransferHelper.safeTransfer(token1, to, amount);

        require(IERC20(token1).balanceOf(to) > balanceBefore, "TF");
    }

    /// @inheritdoc IRadbotReservoirActions
    function sendReserve(
        address to,
        uint256 amount
    ) external override onlyDeployer lock {
        require(to != address(0), "TO");
        require(amount > 0, "IA");

        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        address token;

        // Try token0 first, fallback to token1
        if (amount <= balance0Before) {
            token = token0;
        } else if (amount <= balance1Before) {
            token = token1;
        } else {
            revert("SR"); // Send Reserve error - insufficient balance in both tokens
        }

        TransferHelper.safeTransfer(token, to, amount);
    }
}

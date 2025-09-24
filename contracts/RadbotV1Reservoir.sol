// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IRadbotReservoir.sol";

import "./extensions/ReserveLocked.sol";

import "./interfaces/IRadbotV1ReservoirFactory.sol";

import "./libraries/TransferHelper.sol";

/// @title RadbotV1Reservoir
/// @notice Reservoir contract for managing token reserves and withdrawals
/// @dev Implements IRadbotReservoir interface with epoch-based withdrawal limits
contract RadbotV1Reservoir is IRadbotReservoir, ReserveLocked {
    /// @notice Constant key for token0 withdrawal tracking
    bytes32 public constant WITHDRAW_KEY0 = keccak256("WITHDRAW0");
    /// @notice Constant key for token1 withdrawal tracking
    bytes32 public constant WITHDRAW_KEY1 = keccak256("WITHDRAW1");

    /// @notice Lock state for initialization control
    uint8 private _lock = 0;

    /// @notice The deployer contract associated with this reservoir
    address public override deployer;

    /// @notice Modifier that restricts access to the factory owner only
    modifier onlyFactoryOwner() {
        require(msg.sender == IRadbotV1ReservoirFactory(factory).owner(), "O");
        _;
    }

    /// @notice Modifier that ensures the contract is fully initialized
    modifier lock() {
        require(_lock == 2, "L");
        _;
    }

    /// @notice Modifier that restricts access to the deployer only
    modifier onlyDeployer() {
        require(msg.sender == deployer, "D");
        _;
    }

    /// @notice Constructs a new RadbotV1Reservoir
    /// @dev Sets the owner and initializes parameters from the factory
    constructor() {
        owner = msg.sender;

        (
            factory,
            token0,
            token1,
            epochDuration,
            maxWithdrawPerEpoch0,
            maxWithdrawPerEpoch1,
            upperLimit0,
            upperLimit1
        ) = IRadbotV1ReservoirFactory(msg.sender).parameters();
    }

    /// @notice Initializes the reservoir with a deployer address
    /// @dev Can only be called once by the factory owner
    /// @param deployer_ The deployer contract address to associate with this reservoir
    function initialize(address deployer_) external onlyFactoryOwner {
        require(_lock == 1, "L");
        _lock = 2;
        deployer = deployer_;
    }

    /// @notice Returns the balance of token0 in this reservoir
    /// @return The balance of token0
    function balance0() public view override returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    /// @notice Returns the balance of token1 in this reservoir
    /// @return The balance of token1
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

        require(amount <= balance0() || amount <= balance1(), "IR");

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

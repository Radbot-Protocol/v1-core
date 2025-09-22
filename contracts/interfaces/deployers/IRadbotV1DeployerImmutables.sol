// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Deployer state that never changes
/// @notice These parameters are fixed for a deployer forever, i.e., the methods will always return the same values
/// @dev Forked from Uniswap V3's IUniswapV3PoolImmutables interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1DeployerImmutables {
    /// @notice The contract that deployed the deployer, which must adhere to the IRadbotV1Factory interface
    /// @dev Forked from Uniswap V3's factory function
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the deployer, sorted by address
    /// @dev Forked from Uniswap V3's token0 function
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The deployer's reservoir
    /// @dev Forked from Uniswap V3's reservoir function
    /// @dev This will hold reserves for agents to trade.
    /// @return The deployer reservoir
    function reservoir() external view returns (address);

    /// @notice The second of the two tokens of the deployer, sorted by address
    /// @dev Forked from Uniswap V3's token1 function
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The deployer's fee in hundredths of a bip, i.e. 1e-6
    /// @dev Forked from Uniswap V3's fee function
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The deployer tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @dev Forked from Uniswap V3's tickSpacing function
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a deployer
    /// @dev Forked from Uniswap V3's maxLiquidityPerTick function
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

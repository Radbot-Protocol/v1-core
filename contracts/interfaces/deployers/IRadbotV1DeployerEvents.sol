// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Events emitted by a deployer
/// @notice Contains all events emitted by the deployer
/// @dev Forked from Uniswap V3's IUniswapV3PoolEvents interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1DeployerEvents {
    /// @notice Emitted exactly once by a deployer when #initialize is first called on the deployer
    /// @dev Mint/Burn/Ignite cannot be emitted by the deployer before Initialize
    /// @dev Forked from Uniswap V3's Initialize event
    /// @param sqrtPriceX96 The initial sqrt price of the deployer, as a Q64.96
    /// @param tick The initial tick of the deployer, i.e. log base 1.0001 of the starting price of the deployer
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @dev Forked from Uniswap V3's Mint event
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @dev Forked from Uniswap V3's Collect event
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @dev Forked from Uniswap V3's Burn event
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the deployer for any ignites between token0 and token1
    /// @dev Forked from Uniswap V3's Swap event, renamed to 'Ignite' for RadBot protocol
    /// @param sender The address that initiated the ignite call, and that received the callback
    /// @param recipient The address that received the output of the ignite
    /// @param amount0 The delta of the token0 balance of the deployer
    /// @param amount1 The delta of the token1 balance of the deployer
    /// @param sqrtPriceX96 The sqrt(price) of the deployer after the ignite, as a Q64.96
    /// @param liquidity The liquidity of the deployer after the ignite
    /// @param tick The log base 1.0001 of price of the deployer after the ignite
    event Ignite(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the deployer for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/ignite/burn.
    /// @dev Forked from Uniswap V3's IncreaseObservationCardinalityNext event
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the deployer
    /// @dev Forked from Uniswap V3's SetFeeProtocol event
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(
        uint8 feeProtocol0Old,
        uint8 feeProtocol1Old,
        uint8 feeProtocol0New,
        uint8 feeProtocol1New
    );

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @dev Forked from Uniswap V3's CollectProtocol event
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount1 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(
        address indexed sender,
        address indexed recipient,
        uint128 amount0,
        uint128 amount1
    );
}

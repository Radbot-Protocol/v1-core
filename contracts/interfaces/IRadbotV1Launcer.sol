// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title An interface for a contract that is capable of deploying Radbot V1 Deployers
/// @notice A contract that constructs a deployer must implement this to pass arguments to the deployer
/// @dev This is used to avoid having constructor arguments in the deployer contract, which results in the init code hash
/// of the deployer being constant allowing the CREATE2 address of the deployer to be cheaply computed on-chain
/// @dev Forked from Uniswap V3's IUniswapV3PoolDeployer interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1Launcer {
    /// @notice Get the parameters to be used in constructing the deployer, set transiently during deployer creation.
    /// @dev Called by the deployer constructor to fetch the parameters of the deployer
    /// @dev Forked from Uniswap V3's parameters function
    /// Returns factory The factory address
    /// Returns token0 The first token of the deployer by address sort order
    /// Returns token1 The second token of the deployer by address sort order
    /// Returns fee The fee collected upon every ignite in the deployer, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IRadbotV1DeployerActions#ignite
/// @notice Any contract that calls IRadbotV1DeployerActions#ignite must implement this interface
/// @dev Forked from Uniswap V3's IUniswapV3SwapCallback interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1IgniteCallback {
    /// @notice Called to `msg.sender` after executing an ignite via IRadbotV1DeployerActions#ignite
    /// @dev In the implementation you must pay the deployer tokens owed for the ignite.
    /// The caller of this method must be checked to be a RadbotV1Deployer deployed by the canonical RadbotV1Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were ignited.
    /// @dev Forked from Uniswap V3's uniswapV3SwapCallback function, renamed for RadBot protocol
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the deployer by
    /// the end of the ignite. If positive, the callback must send that amount of token0 to the deployer.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the deployer by
    /// the end of the ignite. If positive, the callback must send that amount of token1 to the deployer.
    /// @param data Any data passed through by the caller via the IRadbotV1DeployerActions#ignite call
    function radbotV1IgniteCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

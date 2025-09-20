// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IRadbotV1DeployerActions#mint
/// @notice Any contract that calls IRadbotV1DeployerActions#mint must implement this interface
/// @dev Forked from Uniswap V3's IUniswapV3MintCallback interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IRadbotV1DeployerActions#mint
    /// @dev In the implementation you must pay the deployer tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a RadbotV1Deployer deployed by the canonical RadbotV1Factory.
    /// @dev Forked from Uniswap V3's uniswapV3MintCallback function
    /// @param amount0Owed The amount of token0 due to the deployer for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the deployer for the minted liquidity
    /// @param data Any data passed through by the caller via the IRadbotV1DeployerActions#mint call
    function radbotV1MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

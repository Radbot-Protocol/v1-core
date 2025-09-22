// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IRadbotV1DeployerActions#mint
/// @notice Any contract that calls IRadbotV1DeployerActions#mint must implement this interface
/// @dev Forked from Uniswap V3's IUniswapV3MintCallback interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1ReserveCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IRadbotV1DeployerActions#mint
    /// @dev In the implementation you must pay the deployer tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a RadbotV1Deployer deployed by the canonical RadbotV1Factory.
    /// @param data Any data passed through by the caller via the IRadbotV1DeployerActions#mint call
    function radbotV1ReserveCallback(bytes calldata data) external;
}

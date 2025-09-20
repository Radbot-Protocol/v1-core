// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IRadbotSynthetic.sol";

/// @title SyntheticHelper
/// @notice Contains helper methods for safely interacting with IRadbotSynthetic tokens
/// @dev This library provides safe wrapper functions for minting and burning synthetic tokens
///      that handle inconsistent return value patterns from different token implementations
library SyntheticHelper {
    /// @notice Safely mints synthetic tokens to a specified address
    /// @dev Handles tokens that may not consistently return true/false on successful operations
    /// @param token The address of the synthetic token contract
    /// @param to The address to mint tokens to
    /// @param value The amount of tokens to mint
    /// @custom:throws "SM" if the mint operation fails or returns false
    function safeMint(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IRadbotSynthetic.mint.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SM"
        );
    }

    /// @notice Safely burns synthetic tokens from a specified address
    /// @dev Handles tokens that may not consistently return true/false on successful operations
    /// @param token The address of the synthetic token contract
    /// @param from The address to burn tokens from
    /// @param value The amount of tokens to burn
    /// @custom:throws "SB" if the burn operation fails or returns false
    function safeBurn(address token, address from, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IRadbotSynthetic.burn.selector, from, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SB"
        );
    }
}

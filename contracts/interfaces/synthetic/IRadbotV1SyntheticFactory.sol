// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./ISyntheticToken.sol";

/// @title Interface for Radbot V1 Synthetic Factory
/// @notice Factory contract for creating and managing synthetic tokens
/// @dev This factory creates RadbotSynthetic tokens with controlled parameters
/// @dev Only supports tokens with 6 or 18 decimal places
interface IRadbotV1SyntheticFactory is ISyntheticToken {
    /// @notice Creates a new synthetic token with the specified parameters
    /// @dev Only allows creation of tokens with 6 or 18 decimal places
    /// @dev The caller becomes the owner of the created synthetic token
    /// @param token The synthetic token parameters
    /// @return synthetic The address of the newly created synthetic token
    function createSynthetic(
        SyntheticToken calldata token
    ) external returns (address synthetic);

    /// @notice Emitted when a new synthetic token is created
    /// @param synthetic The address of the created synthetic token
    /// @param name The name of the synthetic token
    /// @param symbol The symbol of the synthetic token
    /// @param decimals The number of decimal places for the token
    event SyntheticCreated(
        address indexed synthetic,
        bytes32 name,
        bytes16 symbol,
        uint8 decimals
    );

    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @dev Forked from Uniswap V3's owner function
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the address of a synthetic token by symbol and decimals
    /// @dev Returns address(0) if the synthetic token doesn't exist
    /// @param symbol The symbol of the synthetic token
    /// @param decimals The number of decimal places for the token
    /// @return synthetic The address of the synthetic token
    function getSynthetic(
        bytes16 symbol,
        uint8 decimals
    ) external view returns (address synthetic);
}

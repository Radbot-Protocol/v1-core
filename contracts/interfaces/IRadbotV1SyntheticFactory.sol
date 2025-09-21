// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRadbotV1SyntheticFactory {
    function createSynthetic(
        bytes32 name,
        bytes16 symbol,
        uint8 decimals
    ) external returns (address synthetic);

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

    function getSynthetic(
        bytes16 symbol,
        uint8 decimals
    ) external view returns (address synthetic);
}

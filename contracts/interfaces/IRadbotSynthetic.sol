// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Radbot Synthetic Tokens
/// @notice Defines the interface for synthetic tokens used in the Radbot protocol
/// @dev Synthetic tokens are ERC20-compatible tokens with controlled minting and burning capabilities
interface IRadbotSynthetic {
    /// @notice Returns the address authorized to mint and burn tokens
    /// @return The minter address
    function minter() external view returns (address);

    /// @notice Returns the owner of this synthetic token contract
    /// @return The owner address
    function owner() external view returns (address);

    /// @notice Mints new tokens to the specified address
    /// @dev Can only be called by the minter
    /// @param to The address to receive the minted tokens
    /// @param amount The amount of tokens to mint
    /// @return success Whether the mint operation was successful
    /// @return data Additional data returned from the mint operation
    function mint(
        address to,
        uint256 amount
    ) external returns (bool, bytes memory);

    /// @notice Burns tokens from the specified address
    /// @dev Can only be called by the minter
    /// @param from The address to burn tokens from
    /// @param amount The amount of tokens to burn
    /// @return success Whether the burn operation was successful
    /// @return data Additional data returned from the burn operation
    function burn(
        address from,
        uint256 amount
    ) external returns (bool, bytes memory);

    /// @notice Returns the balance of the specified account
    /// @param account The address to query the balance for
    /// @return The token balance of the account
    function balance(address account) external view returns (uint256);
}

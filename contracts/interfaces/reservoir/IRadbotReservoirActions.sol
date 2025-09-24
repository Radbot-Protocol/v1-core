// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Radbot Reservoir Actions
/// @notice Defines the core actions that can be performed on a reservoir
/// @dev These functions handle token balance queries and reserve operations
interface IRadbotReservoirActions {
    /// @notice Returns the balance of token0 in this reservoir
    /// @return The balance of token0
    function balance0() external view returns (uint256);

    /// @notice Returns the balance of token1 in this reservoir
    /// @return The balance of token1
    function balance1() external view returns (uint256);

    /// @notice Reserves token0 (placeholder for future implementation)
    /// @dev Will be implemented in future versions
    function reserve0() external;

    /// @notice Reserves token1 (placeholder for future implementation)
    /// @dev Will be implemented in future versions
    function reserve1() external;

    /// @notice Sends reserve tokens to the specified address
    /// @dev Can only be called by the associated deployer
    /// @param to The address to send tokens to
    /// @param amount The amount of tokens to send
    function sendReserve(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Radbot Reservoir Owner Actions
/// @notice Defines the actions that can only be performed by the reservoir owner
/// @dev These functions are restricted to the owner and have epoch-based limitations
interface IRadbotReservoirOwnerActions {
    /// @notice Withdraws token0 from the reservoir to the specified address
    /// @dev Can only be called by the owner and is subject to epoch limits
    /// @param to The address to receive the withdrawn tokens
    /// @param amount The amount of token0 to withdraw
    function withdraw0(address to, uint256 amount) external;

    /// @notice Withdraws token1 from the reservoir to the specified address
    /// @dev Can only be called by the owner and is subject to epoch limits
    /// @param to The address to receive the withdrawn tokens
    /// @param amount The amount of token1 to withdraw
    function withdraw1(address to, uint256 amount) external;

    /// @notice Initializes the reservoir with a deployer address
    /// @dev Can only be called once by the factory owner
    /// @param deployer_ The deployer contract address to associate with this reservoir
    function initialize(address deployer_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Radbot Reservoir Immutables
/// @notice Defines the immutable parameters of a reservoir that never change
/// @dev These parameters are set during reservoir creation and remain constant
interface IRadbotReservoirImmutables {
    /// @notice Returns the factory contract that created this reservoir
    /// @return The factory address
    function factory() external view returns (address);

    /// @notice Returns the deployer contract associated with this reservoir
    /// @return The deployer address
    function deployer() external view returns (address);

    /// @notice Returns the owner of this reservoir
    /// @return The owner address
    function owner() external view returns (address);

    /// @notice Returns the first token of the reservoir
    /// @return The token0 address
    function token0() external view returns (address);

    /// @notice Returns the second token of the reservoir
    /// @return The token1 address
    function token1() external view returns (address);

    /// @notice Returns the duration of each epoch in seconds
    /// @return The epoch duration
    function epochDuration() external view returns (uint256);

    /// @notice Returns the maximum amount of token0 that can be withdrawn per epoch
    /// @return The maximum withdrawal amount for token0
    function maxWithdrawPerEpoch0() external view returns (uint256);

    /// @notice Returns the maximum amount of token1 that can be withdrawn per epoch
    /// @return The maximum withdrawal amount for token1
    function maxWithdrawPerEpoch1() external view returns (uint256);

    /// @notice Returns the upper limit for token0 operations
    /// @return The upper limit for token0
    function upperLimit0() external view returns (uint256);

    /// @notice Returns the upper limit for token1 operations
    /// @return The upper limit for token1
    function upperLimit1() external view returns (uint256);
}

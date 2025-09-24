// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title IRadbotReservoirDerivedActions
/// @notice Interface for derived actions that provide view functions for reservoir capacity and withdrawal tracking
/// @dev These functions are derived from the core reservoir state and provide additional utility
interface IRadbotReservoirDerivedActions {
    /// @notice Get the remaining withdrawal capacity for token0 in the current epoch
    /// @dev Calculates capacity based on reservoir balance and upper limits, accounting for already withdrawn amounts
    /// @return remaining The amount of token0 that can still be withdrawn in the current epoch
    function getRemainingEpochCapacityToken0()
        external
        view
        returns (uint256 remaining);

    /// @notice Get the remaining withdrawal capacity for token1 in the current epoch
    /// @dev Calculates capacity based on reservoir balance and upper limits, accounting for already withdrawn amounts
    /// @return remaining The amount of token1 that can still be withdrawn in the current epoch
    function getRemainingEpochCapacityToken1()
        external
        view
        returns (uint256 remaining);

    /// @notice Get the remaining withdrawal capacity for both tokens in the current epoch
    /// @dev Convenience function that returns both token0 and token1 remaining capacity
    /// @return remainingToken0 The amount of token0 that can still be withdrawn in the current epoch
    /// @return remainingToken1 The amount of token1 that can still be withdrawn in the current epoch
    function getRemainingEpochCapacityBoth()
        external
        view
        returns (uint256 remainingToken0, uint256 remainingToken1);

    /// @notice Get the total amount withdrawn for a specific token in a specific epoch
    /// @dev Returns 0 if the epoch hasn't been reached yet or if no withdrawals occurred
    /// @param epoch The epoch number to query
    /// @param tokenIndex The token index (0 for token0, 1 for token1)
    /// @return withdrawn The total amount withdrawn for the specified token in the specified epoch
    function getEpochWithdrawn(
        uint256 epoch,
        uint8 tokenIndex
    ) external view returns (uint256 withdrawn);

    /// @notice Get the total amount withdrawn for both tokens in a specific epoch
    /// @dev Convenience function that returns both token0 and token1 withdrawal amounts for an epoch
    /// @param epoch The epoch number to query
    /// @return withdrawnToken0 The total amount of token0 withdrawn in the specified epoch
    /// @return withdrawnToken1 The total amount of token1 withdrawn in the specified epoch
    function getEpochWithdrawnBoth(
        uint256 epoch
    ) external view returns (uint256 withdrawnToken0, uint256 withdrawnToken1);

    /// @notice Get the current epoch number
    /// @dev Returns the current epoch that the contract is in
    /// @return The current epoch number
    function getCurrentEpoch() external view returns (uint256);

    /// @notice Get the timestamp when the current epoch started
    /// @dev Returns the start time of the current epoch
    /// @return The timestamp when the current epoch began
    function getEpochStartTime() external view returns (uint256);

    /// @notice Get the time remaining in the current epoch
    /// @dev Calculates how much time is left before the current epoch ends
    /// @return The number of seconds remaining in the current epoch, or 0 if epoch has ended
    function getTimeRemainingInEpoch() external view returns (uint256);

    /// @notice Get the last executed epoch for a specific key
    /// @dev Returns the epoch number when the operation with the given key was last executed
    /// @param key The unique key identifying the operation
    /// @return The epoch number when the operation was last executed
    function getLastExecutedEpoch(bytes32 key) external view returns (uint256);

    /// @notice Get comprehensive epoch information
    /// @dev Returns all relevant epoch data in a single call for convenience
    /// @return currentEpoch The current epoch number
    /// @return epochStartTime The timestamp when the current epoch started
    /// @return timeRemaining The number of seconds remaining in the current epoch
    /// @return epochDurationSec The duration of each epoch in seconds
    function getEpochInfo()
        external
        view
        returns (
            uint256 currentEpoch,
            uint256 epochStartTime,
            uint256 timeRemaining,
            uint256 epochDurationSec
        );
}

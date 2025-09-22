// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRadbotReservoirEvents {
    /// @notice Emitted when a new epoch begins
    /// @param newEpoch The new epoch number
    /// @param epochStartTime The timestamp when the new epoch started
    event EpochAdvanced(uint256 newEpoch, uint256 epochStartTime);

    /// @notice Emitted when an operation is executed in a specific epoch
    /// @param key The unique key identifying the operation
    /// @param epoch The epoch in which the operation was executed
    event ExecutedInEpoch(bytes32 indexed key, uint256 epoch);

    /// @notice Emitted when tokens are withdrawn in a specific epoch
    /// @param epoch The epoch in which the withdrawal occurred
    /// @param token The amount of tokens withdrawn
    /// @param amount The address that received the tokens
    event WithdrawnInEpoch(
        uint256 indexed epoch,
        address indexed token,
        uint256 amount
    );
}

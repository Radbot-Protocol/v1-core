// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for Radbot Reservoir Operations
/// @notice Any contract that interacts with reservoir operations must implement this interface
/// @dev This callback is used for reservoir-related operations in the Radbot protocol
/// @author RadBot
interface IRadbotV1ReserveCallback {
    /// @notice Called to `msg.sender` after reservoir operations
    /// @dev In the implementation you must handle any required token transfers or state updates.
    /// The caller of this method must be checked to be a valid Radbot contract.
    /// @param data Any data passed through by the caller via the reservoir operation call
    function radbotV1ReserveCallback(bytes calldata data) external;
}

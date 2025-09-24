// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Interface for Synthetic Token Structure
/// @notice Defines the data structure for synthetic tokens in the Radbot protocol
/// @dev This interface defines the structure used to create synthetic tokens with controlled parameters
interface ISyntheticToken {
    /// @notice Structure representing a synthetic token
    /// @param name The name of the synthetic token (stored as bytes32)
    /// @param symbol The symbol of the synthetic token (stored as bytes16)
    /// @param decimals The number of decimal places for the token (must be 6 or 18)
    struct SyntheticToken {
        bytes32 name;
        bytes16 symbol;
        uint8 decimals;
    }
}

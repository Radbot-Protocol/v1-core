// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title ISyntheticToken
/// @notice Interface for synthetic tokens
/// @dev This interface defines the structure of synthetic tokens

interface ISyntheticToken {
    struct SyntheticToken {
        bytes32 name;
        bytes16 symbol;
        uint8 decimals;
    }
}

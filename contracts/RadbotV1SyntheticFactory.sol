// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/synthetic/IRadbotV1SyntheticFactory.sol";
import "./libraries/StringHelper.sol";
import "./RadbotSynthetic.sol";
import "./NoDelegateCall.sol";

/// @title RadbotV1SyntheticFactory
/// @notice Factory contract for creating and managing synthetic tokens
/// @dev This factory creates RadbotSynthetic tokens with controlled parameters
/// @dev Only supports tokens with 6 or 18 decimal places
contract RadbotV1SyntheticFactory is IRadbotV1SyntheticFactory, NoDelegateCall {
    using StringHelper for bytes32;
    using StringHelper for bytes16;

    /// @notice The owner of this factory contract
    /// @dev Set during construction to msg.sender
    address public override owner;

    /// @notice Mapping from symbol and decimals to synthetic token address
    /// @dev getSynthetic[symbol][decimals] = syntheticTokenAddress
    /// @dev Used to track and retrieve created synthetic tokens
    mapping(bytes16 => mapping(uint8 => address)) public override getSynthetic;

    /// @notice Constructs a new RadbotV1SyntheticFactory
    /// @dev Sets the deployer as the initial owner
    constructor(address owner_) {
        owner = owner_;
    }

    /// @notice Creates a new synthetic token with the specified parameters
    /// @dev Only allows creation of tokens with 6 or 18 decimal places
    /// @dev The caller becomes the owner of the created synthetic token
    /// @dev Uses StringHelper library to convert bytes32/bytes16 to strings
    /// @param token The synthetic token
    /// @return synthetic The address of the newly created synthetic token
    function createSynthetic(
        SyntheticToken calldata token
    ) external override noDelegateCall returns (address synthetic) {
        require(token.decimals == 18 || token.decimals == 6, "CS");
        require(token.name != bytes32(0), "CN"); // Check name is not empty
        require(token.symbol != bytes16(0), "CSY"); // Check symbol is not empty

        // Check if synthetic already exists
        synthetic = getSynthetic[token.symbol][token.decimals];
        if (synthetic != address(0)) {
            return synthetic; // Return existing synthetic
        }

        synthetic = address(
            new RadbotSynthetic(
                owner,
                token.name.bytes32ToString(), // Lib checks for length
                token.symbol.bytes16ToString() // Lib checks for length
            )
        );

        // Store the synthetic address in the mapping
        getSynthetic[token.symbol][token.decimals] = synthetic;

        // Emit the SyntheticCreated event
        emit SyntheticCreated(
            synthetic,
            token.name,
            token.symbol,
            token.decimals
        );
    }
}

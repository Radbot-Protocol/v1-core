// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IRadbotV1SyntheticFactory.sol";
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
    constructor() {
        owner = msg.sender;
    }

    /// @notice Creates a new synthetic token with the specified parameters
    /// @dev Only allows creation of tokens with 6 or 18 decimal places
    /// @dev The caller becomes the owner of the created synthetic token
    /// @dev Uses StringHelper library to convert bytes32/bytes16 to strings
    /// @param name The name of the synthetic token (as bytes32)
    /// @param symbol The symbol of the synthetic token (as bytes16)
    /// @param decimals The number of decimal places (must be 6 or 18)
    /// @return synthetic The address of the newly created synthetic token
    function createSynthetic(
        bytes32 name,
        bytes16 symbol,
        uint8 decimals
    ) external override noDelegateCall returns (address synthetic) {
        require(decimals == 18 || decimals == 6, "CS");
        require(name != bytes32(0), "CN"); // Check name is not empty
        require(symbol != bytes16(0), "CSY"); // Check symbol is not empty

        synthetic = address(
            new RadbotSynthetic(
                msg.sender,
                name.bytes32ToString(), // Lib checks for length
                symbol.bytes16ToString() // Lib checks for length
            )
        );

        // Store the synthetic address in the mapping
        getSynthetic[symbol][decimals] = synthetic;

        // Emit the SyntheticCreated event
        emit SyntheticCreated(synthetic, name, symbol, decimals);
    }
}

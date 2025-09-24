// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./interfaces/IRadbotV1Launcher.sol";
import {RadbotV1Deployer} from "./RadbotV1Deployer.sol";

/// @title RadbotV1Launcher
/// @notice Launches RadbotV1Deployer contracts with the necessary parameters
/// @dev This contract handles the transient parameter storage and deployment of new deployer instances
contract RadbotV1Launcher is IRadbotV1Launcher {
    /// @notice Parameters structure for deployer creation
    /// @param factory The contract address of the Radbot V1 factory
    /// @param token0 The first token of the deployer by address sort order
    /// @param token1 The second token of the deployer by address sort order
    /// @param fee The fee collected upon every ignite in the deployer, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    /// @inheritdoc IRadbotV1Launcher
    Parameters public override parameters;

    /// @notice Deploys a deployer with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the deployer
    /// @dev Uses CREATE2 to deploy deployer contracts with deterministic addresses
    /// @param factory The contract address of the Radbot V1 factory
    /// @param token0 The first token of the deployer by address sort order
    /// @param token1 The second token of the deployer by address sort order
    /// @param fee The fee collected upon every ignite in the deployer, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    /// @return deployer The address of the newly deployed RadbotV1Deployer contract
    function launch(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address deployer) {
        parameters = Parameters({
            factory: factory,
            token0: token0,
            token1: token1,
            fee: fee,
            tickSpacing: tickSpacing
        });

        deployer = address(
            new RadbotV1Deployer{
                salt: keccak256(abi.encode(token0, token1, fee))
            }()
        );

        delete parameters;
    }
}

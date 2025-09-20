// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./deployers/IRadbotV1DeployerImmutables.sol";
import "./deployers/IRadbotV1DeployerState.sol";
import "./deployers/IRadbotV1DeployerDerivedState.sol";
import "./deployers/IRadbotV1DeployerActions.sol";
import "./deployers/IRadbotV1DeployerOwnerActions.sol";
import "./deployers/IRadbotV1DeployerEvents.sol";

/// @title The interface for a Radbot V1 Deployer
/// @notice A Radbot deployer facilitates igniting and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The deployer interface is broken up into many smaller pieces
/// @dev Forked from Uniswap V3's IUniswapV3Pool interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1Deployer is
    IRadbotV1DeployerImmutables,
    IRadbotV1DeployerState,
    IRadbotV1DeployerDerivedState,
    IRadbotV1DeployerActions,
    IRadbotV1DeployerOwnerActions,
    IRadbotV1DeployerEvents
{

}

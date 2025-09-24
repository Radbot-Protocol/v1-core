// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./reservoir/IRadbotReservoirActions.sol";
import "./reservoir/IRadbotReservoirOwnerActions.sol";

/// @title Interface for Radbot Reservoir
/// @notice Defines the interface for reservoir contracts that manage token reserves
/// @dev Reservoirs handle token storage and withdrawal operations with epoch-based limits
interface IRadbotReservoir is
    IRadbotReservoirActions,
    IRadbotReservoirOwnerActions
{

}

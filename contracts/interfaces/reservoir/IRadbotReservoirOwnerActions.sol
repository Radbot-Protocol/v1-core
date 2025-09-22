// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRadbotReservoirOwnerActions {
    function withdraw0(address to, uint256 amount) external;

    function withdraw1(address to, uint256 amount) external;
}

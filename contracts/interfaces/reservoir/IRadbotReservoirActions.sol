// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRadbotReservoirActions {
    function balance0() external view returns (uint256);

    function balance1() external view returns (uint256);

    function reserve0() external;

    function reserve1() external;
}

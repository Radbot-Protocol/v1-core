// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRadbotReservoirImmutables {
    function factory() external view returns (address);

    function deployer() external view returns (address);

    function owner() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function epochDuration() external view returns (uint256);

    function maxWithdrawPerEpoch0() external view returns (uint256);

    function maxWithdrawPerEpoch1() external view returns (uint256);

    ///@dev This is the max withdraw per epoch for the reservoir (sum of both tokens) maxWithdrawPerEpoch0 + maxWithdrawPerEpoch1 == maxWithdrawPerEpochR

    function maxWithdrawPerEpochR() external view returns (uint256);

    function upperLimit0() external view returns (uint256);

    function upperLimit1() external view returns (uint256);

    ///@dev This is the upper limit for the reservoir (sum of both tokens) upperLimit0 + upperLimit1 == upperLimitR

    function upperLimitR() external view returns (uint256);
}

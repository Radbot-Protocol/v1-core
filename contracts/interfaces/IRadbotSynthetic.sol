// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRadbotSynthetic {
    function minter() external view returns (address);

    function owner() external view returns (address);

    function mint(
        address to,
        uint256 amount
    ) external returns (bool, bytes memory);

    function burn(
        address from,
        uint256 amount
    ) external returns (bool, bytes memory);

    function balance(address account) external view returns (uint256);
}

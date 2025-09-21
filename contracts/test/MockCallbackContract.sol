// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/callbacks/IRadbotV1MintCallback.sol";
import "../interfaces/callbacks/IRadbotV1IgniteCallback.sol";
import "../interfaces/IRadbotV1Deployer.sol";

contract MockCallbackContract is
    IRadbotV1MintCallback,
    IRadbotV1IgniteCallback
{
    address public deployer;

    constructor(address _deployer) {
        deployer = _deployer;
    }

    function radbotV1MintCallback(
        uint256 /*amount0Owed */,
        uint256 /*amount1Owed */,
        bytes calldata /*data */
    ) external view override {
        // Only allow the deployer to call this callback
        require(msg.sender == deployer, "Unauthorized callback");

        // For testing purposes, we don't actually transfer tokens
        // In a real implementation, you would transfer the required amounts
        // of token0 and token1 to the deployer contract

        // Example of what would happen in a real implementation:
        // IERC20(token0).transfer(deployer, amount0Owed);
        // IERC20(token1).transfer(deployer, amount1Owed);
    }

    function radbotV1IgniteCallback(
        int256 /*amount0Delta */,
        int256 /*amount1Delta */,
        bytes calldata /*data */
    ) external view override {
        // Only allow the deployer to call this callback
        require(msg.sender == deployer, "Unauthorized callback");

        // For testing purposes, we don't actually transfer tokens
        // In a real implementation, you would handle the token transfers
        // based on the deltas (positive = owed to pool, negative = owed to you)

        // Example of what would happen in a real implementation:
        // if (amount0Delta > 0) {
        //     IERC20(token0).transfer(deployer, uint256(amount0Delta));
        // }
        // if (amount1Delta > 0) {
        //     IERC20(token1).transfer(deployer, uint256(amount1Delta));
        // }
    }

    // Helper function to call mint on the deployer directly
    // This avoids the delegate call detection issue
    function mintLiquidity(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        // Call the deployer's mint function directly from this contract
        // This ensures the call comes from this contract's address, not via delegate call
        return
            IRadbotV1Deployer(deployer).mint(
                recipient,
                tickLower,
                tickUpper,
                amount,
                data
            );
    }

    // Helper function to call burn on the deployer directly
    function burnLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1) {
        return IRadbotV1Deployer(deployer).burn(tickLower, tickUpper, amount);
    }

    // Helper function to call collect on the deployer directly
    function collectFees(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1) {
        return
            IRadbotV1Deployer(deployer).collect(
                recipient,
                tickLower,
                tickUpper,
                amount0Requested,
                amount1Requested
            );
    }
}

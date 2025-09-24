// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title An interface for a contract that is capable of deploying Radbot V1 Deployers
/// @notice A contract that constructs a deployer must implement this to pass arguments to the deployer
/// @dev This is used to avoid having constructor arguments in the deployer contract, which results in the init code hash
/// of the deployer being constant allowing the CREATE2 address of the deployer to be cheaply computed on-chain
/// @dev Forked from Uniswap V3's IUniswapV3PoolDeployer interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1ReservoirFactory {
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint256 epochDuration,
            uint256 maxWithdrawPerEpoch0,
            uint256 maxWithdrawPerEpoch1,
            uint256 upperLimit0,
            uint256 upperLimit1
        );

    function createReservoir(
        address token0,
        address token1,
        address deployer
    ) external returns (address deployed);

    function owner() external view returns (address);

    function reservoir(
        address token0,
        address token1,
        address deployer
    ) external view returns (address);
}

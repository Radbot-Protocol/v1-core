// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for the Radbot V1 Factory
/// @notice The Radbot V1 Factory facilitates creation of Radbot V1 deployers and control over the protocol fees
/// @dev Forked from Uniswap V3's IUniswapV3Factory interface
/// @author Uniswap Labs (original implementation)
/// @author RadBot (modifications and adaptations)
interface IRadbotV1Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a deployer is created
    /// @dev Forked from Uniswap V3's PoolCreated event
    /// @param token0 The first token of the deployer by address sort order
    /// @param token1 The second token of the deployer by address sort order
    /// @param fee The fee collected upon every ignite in the deployer, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param deployer The address of the created deployer
    event DeployerCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address deployer
    );

    /// @notice Emitted when a new fee amount is enabled for deployer creation via the factory
    /// @dev Forked from Uniswap V3's FeeAmountEnabled event
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for deployers created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @dev Forked from Uniswap V3's owner function
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @dev Forked from Uniswap V3's feeAmountTickSpacing function
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the deployer address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @dev Forked from Uniswap V3's getPool function
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every ignite in the deployer, denominated in hundredths of a bip
    /// @return deployer The deployer address
    function getDeployer(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address deployer);

    /// @notice Creates a deployer for the given two tokens and fee
    /// @dev Forked from Uniswap V3's createPool function
    /// @param tokenA One of the two tokens in the desired deployer
    /// @param tokenB The other of the two tokens in the desired deployer
    /// @param fee The desired fee for the deployer
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the deployer already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return deployer The address of the newly created deployer
    function create(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address deployer);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @dev Forked from Uniswap V3's setOwner function
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @dev Forked from Uniswap V3's enableFeeAmount function
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all deployers created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IRadbotSynthetic.sol";
import "./external/openzeppline/ERC20.sol";

/// @title RadbotSynthetic
/// @notice A synthetic token contract that implements ERC20 functionality with controlled minting and burning
/// @dev This contract extends ERC20 and implements IRadbotSynthetic interface
/// @dev The contract has a two-phase initialization: construction and initialization
/// @dev Only the designated minter can mint/burn tokens after initialization
contract RadbotSynthetic is IRadbotSynthetic, ERC20 {
    /// @notice The owner of this synthetic token contract
    /// @dev Can only be set during construction
    address public override owner;

    /// @notice The address authorized to mint and burn tokens
    /// @dev Set during initialization, can only be changed by owner
    address public override minter;

    /// @notice Lock state for initialization control
    /// @dev 0 = not initialized, 1 = constructed but not initialized, 2 = fully initialized
    uint8 private locked = 0;

    /// @notice Modifier that restricts access to the owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "O");
        _;
    }

    /// @notice Modifier that ensures the contract is fully initialized
    /// @dev Prevents operations before initialization is complete
    modifier lock() {
        require(locked == 2);
        _;
    }

    /// @notice Modifier that restricts access to the minter only
    modifier onlyMinter() {
        require(msg.sender == minter, "M");
        _;
    }

    /// @notice Constructs a new RadbotSynthetic token
    /// @dev Sets the owner and initializes the contract in locked state
    /// @param owner_ The address that will own this synthetic token
    /// @param name_ The name of the synthetic token
    /// @param symbol_ The symbol of the synthetic token
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {
        owner = owner_;
        locked = 1;
    }

    /// @notice Initializes the synthetic token with initial supply and minter
    /// @dev Can only be called once by the owner after construction
    /// @dev Mints initial supply to deployer and sets the minter
    /// @param deployer_ The address to receive the initial token supply
    /// @param amount_ The initial amount of tokens to mint
    function initialize(address deployer_, uint256 amount_) external onlyOwner {
        require(locked == 1, "L");
        locked = 2;
        _mint(deployer_, amount_);
        _setMinter(deployer_);
    }

    /// @notice Mints new tokens to the specified address
    /// @dev Can only be called by the minter after initialization
    /// @param to The address to receive the minted tokens
    /// @param amount The amount of tokens to mint
    /// @return success Always returns true on successful mint
    /// @return data Empty bytes array
    function mint(
        address to,
        uint256 amount
    ) external override onlyMinter lock returns (bool, bytes memory) {
        super._mint(to, amount);
        return (true, "");
    }

    /// @notice Burns tokens from the specified address
    /// @dev Can only be called by the minter after initialization
    /// @param from The address to burn tokens from
    /// @param amount The amount of tokens to burn
    /// @return success Always returns true on successful burn
    /// @return data Empty bytes array
    function burn(
        address from,
        uint256 amount
    ) external override onlyMinter lock returns (bool, bytes memory) {
        super._burn(from, amount);
        return (true, "");
    }

    /// @notice Returns the balance of the specified account
    /// @dev Wrapper around ERC20's balanceOf function
    /// @param account The address to query the balance for
    /// @return The token balance of the account
    function balance(address account) external view returns (uint256) {
        return super.balanceOf(account);
    }

    /// @notice Sets the minter address
    /// @dev Internal function that can only be called during initialization
    /// @param minter_ The address to set as the minter
    function _setMinter(address minter_) private {
        minter = minter_;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/reservoir/IRadbotReservoirImmutables.sol";
import "../interfaces/reservoir/IRadbotReservoirEvents.sol";
import "../interfaces/reservoir/IRadbotReservoirDerivedActions.sol";

import "../external/openzeppline/IERC20.sol";

import "../libraries/LowGasSafeMath.sol";

import "../libraries/FullMath.sol";

abstract contract ReserveLocked is
    IRadbotReservoirImmutables,
    IRadbotReservoirEvents,
    IRadbotReservoirDerivedActions
{
    using LowGasSafeMath for uint256;

    /// @inheritdoc IRadbotReservoirImmutables
    address public immutable override factory;

    /// @inheritdoc IRadbotReservoirImmutables
    address public immutable override owner;
    /// @inheritdoc IRadbotReservoirImmutables
    address public immutable override token0;
    /// @inheritdoc IRadbotReservoirImmutables
    address public immutable override token1;

    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override maxWithdrawPerEpoch0;
    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override maxWithdrawPerEpoch1;
    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override maxWithdrawPerEpochR;
    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override upperLimit0;
    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override upperLimit1;
    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override upperLimitR;

    /// @inheritdoc IRadbotReservoirImmutables
    uint256 public immutable override epochDuration;

    uint256 private _currentEpoch;

    uint256 private _epochStartTime;

    mapping(bytes32 => uint256) private _lastExecutedEpoch;

    mapping(uint256 => uint256) private _epochWithdrawn;

    mapping(uint256 => uint256) private _epochWithdrawn0;

    mapping(uint256 => uint256) private _epochWithdrawn1;

    modifier onlyOncePerEpoch(bytes32 key) {
        _advanceEpochIfNeeded();

        require(_lastExecutedEpoch[key] < _currentEpoch, "LE");

        _lastExecutedEpoch[key] = _currentEpoch;

        _lastExecutedEpoch[key] = _currentEpoch;
        emit ExecutedInEpoch(key, _currentEpoch);

        _;
    }

    modifier withdrawToken0WithinEpochLimit(uint256 amount) {
        _advanceEpochIfNeeded();

        uint256 poolBalance = IERC20(token0).balanceOf(address(this));

        uint256 epochCap;
        if (poolBalance > maxWithdrawPerEpoch0) {
            epochCap = FullMath.mulDiv(poolBalance, upperLimit0, 10_000);
        } else {
            epochCap = maxWithdrawPerEpoch0;
        }

        uint256 withdrawnSoFar = _epochWithdrawn0[_currentEpoch];

        require(withdrawnSoFar + amount <= epochCap, "WLE");

        _epochWithdrawn0[_currentEpoch] = withdrawnSoFar + amount;

        emit WithdrawnInEpoch(_currentEpoch, token0, amount);
        _;
    }

    modifier withdrawToken1WithinEpochLimit(uint256 amount) {
        _advanceEpochIfNeeded();

        uint256 poolBalance = IERC20(token1).balanceOf(address(this));

        uint256 epochCap;
        if (poolBalance > maxWithdrawPerEpoch1) {
            epochCap = FullMath.mulDiv(poolBalance, upperLimit1, 10_000);
        } else {
            epochCap = maxWithdrawPerEpoch1;
        }

        uint256 withdrawnSoFar = _epochWithdrawn1[_currentEpoch];
        require(withdrawnSoFar + amount <= epochCap, "WLE");

        _epochWithdrawn1[_currentEpoch] = withdrawnSoFar + amount;

        emit WithdrawnInEpoch(_currentEpoch, token1, amount);
        _;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getCurrentEpoch() public view override returns (uint256) {
        return _currentEpoch;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getEpochStartTime() public view override returns (uint256) {
        return _epochStartTime;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getTimeRemainingInEpoch() public view override returns (uint256) {
        uint256 elapsed = _blockTimestamp() - _epochStartTime;
        if (elapsed >= epochDuration) return 0;
        return epochDuration - elapsed;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getLastExecutedEpoch(
        bytes32 key
    ) public view override returns (uint256) {
        return _lastExecutedEpoch[key];
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getEpochInfo()
        public
        view
        override
        returns (
            uint256 currentEpoch,
            uint256 epochStartTime,
            uint256 timeRemaining,
            uint256 epochDurationSec
        )
    {
        currentEpoch = _currentEpoch;
        epochStartTime = _epochStartTime;
        timeRemaining = getTimeRemainingInEpoch();
        epochDurationSec = epochDuration;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getRemainingEpochCapacityToken0()
        public
        view
        override
        returns (uint256 remaining)
    {
        uint256 poolBalance = IERC20(token0).balanceOf(address(this));

        uint256 epochCap;
        if (poolBalance > maxWithdrawPerEpoch0) {
            epochCap = FullMath.mulDiv(poolBalance, upperLimit0, 10_000);
        } else {
            epochCap = maxWithdrawPerEpoch0;
        }

        uint256 withdrawnSoFar = _epochWithdrawn0[_currentEpoch];
        if (epochCap <= withdrawnSoFar) {
            return 0;
        }

        remaining = epochCap - withdrawnSoFar;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getRemainingEpochCapacityToken1()
        public
        view
        override
        returns (uint256 remaining)
    {
        uint256 poolBalance = IERC20(token1).balanceOf(address(this));

        uint256 epochCap;
        if (poolBalance > maxWithdrawPerEpoch1) {
            epochCap = FullMath.mulDiv(poolBalance, upperLimit1, 10_000);
        } else {
            epochCap = maxWithdrawPerEpoch1;
        }

        uint256 withdrawnSoFar = _epochWithdrawn1[_currentEpoch];
        if (epochCap <= withdrawnSoFar) {
            return 0;
        }

        remaining = epochCap - withdrawnSoFar;
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getRemainingEpochCapacityBoth()
        public
        view
        override
        returns (uint256 remainingToken0, uint256 remainingToken1)
    {
        remainingToken0 = getRemainingEpochCapacityToken0();
        remainingToken1 = getRemainingEpochCapacityToken1();
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getEpochWithdrawn(
        uint256 epoch,
        uint8 tokenIndex
    ) public view override returns (uint256 withdrawn) {
        if (tokenIndex == 0) {
            withdrawn = _epochWithdrawn0[epoch];
        } else if (tokenIndex == 1) {
            withdrawn = _epochWithdrawn1[epoch];
        } else {
            revert("IT");
        }
    }

    /// @inheritdoc IRadbotReservoirDerivedActions
    function getEpochWithdrawnBoth(
        uint256 epoch
    )
        public
        view
        override
        returns (uint256 withdrawnToken0, uint256 withdrawnToken1)
    {
        withdrawnToken0 = _epochWithdrawn0[epoch];
        withdrawnToken1 = _epochWithdrawn1[epoch];
    }

    function _advanceEpochIfNeeded() private {
        uint256 elapsed = block.timestamp - _epochStartTime;
        if (elapsed >= epochDuration) {
            uint256 epochsPassed = elapsed / epochDuration;
            _currentEpoch += epochsPassed;
            _epochStartTime = _epochStartTime + epochsPassed * epochDuration;

            emit EpochAdvanced(_currentEpoch, _epochStartTime);
        }
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp; // truncation is desired
    }
}

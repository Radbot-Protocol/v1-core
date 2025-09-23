// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./NoDelegateCall.sol";

import "./RadbotV1Reservoir.sol";

import "./interfaces/IRadbotV1ReservoirFactory.sol";

contract RadbotV1ReservoirFactory is IRadbotV1ReservoirFactory, NoDelegateCall {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint256 epochDuration;
        uint256 maxWithdrawPerEpoch0;
        uint256 maxWithdrawPerEpoch1;
        uint256 maxWithdrawPerEpochR;
        uint256 upperLimit0;
        uint256 upperLimit1;
        uint256 upperLimitR;
    }

    address public immutable override owner;

    mapping(address => mapping(address => address)) public override reservoir;

    Parameters public override parameters;

    constructor(address factory_) {
        owner = factory_;
    }

    function createReservoir(
        address token0,
        address token1
    ) external override noDelegateCall returns (address deployed) {
        require(msg.sender == owner, "O");
        require(token0 != token1, "TA");
        require(token0 != address(0), "TO");
        require(token1 != address(0), "TO");
        require(reservoir[token0][token1] == address(0), "RD");

        parameters = Parameters({
            factory: address(this),
            token0: token0,
            token1: token1,
            epochDuration: 1 days,
            maxWithdrawPerEpoch0: 2500 * 10 ** 6,
            maxWithdrawPerEpoch1: 2500 * 10 ** 6,
            maxWithdrawPerEpochR: 5000 * 10 ** 6,
            upperLimit0: 1500,
            upperLimit1: 1500,
            upperLimitR: 3000
        });

        deployed = address(
            new RadbotV1Reservoir{salt: keccak256(abi.encode(token0, token1))}()
        );

        reservoir[token0][token1] = deployed;
        reservoir[token1][token0] = deployed;

        delete parameters;
    }
}

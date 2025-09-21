# RadBot V1 Core

A decentralized agent manager protocol built on Ethereum, forked from Uniswap V3 with custom modifications for synthetic token trading and liquidity provision.

## Overview

RadBot V1 Core implements a decentralized agent management system with the following key features:

- **Concentrated Liquidity**: Provide liquidity within custom price ranges for increased capital efficiency
- **Synthetic Tokens**: Create and manage synthetic tokens with controlled minting/burning
- **Ignite Functionality**: Token swapping mechanism (equivalent to Uniswap's swap)
- **Multiple Fee Tiers**: Support for 0.05%, 0.3%, and 1% fee tiers
- **Oracle Integration**: Built-in price oracle for external integrations

## Architecture

### Core Contracts

- **RadbotV1Factory**: Factory contract for creating new deployer instances
- **RadbotV1Deployer**: Main Deployer contract handling agents ignition
- **RadbotV1Launcher**: Handles deterministic deployment of deployer contracts
- **RadbotV1SyntheticFactory**: Factory for creating synthetic tokens
- **RadbotSynthetic**: ERC20 synthetic token with controlled minting

### Key Features

- **Concentrated Liquidity**: Liquidity providers can specify custom price ranges
- **Oracle Updates**: Real-time price and liquidity observations

## Usage

This project uses:

- **Hardhat 3 Beta** for development framework
- **Solidity 0.8.28** for smart contracts
- **TypeScript** for testing and tooling
- **Mocha** for test framework
- **Ethers.js** for Ethereum interactions

## License

BUSL-1.1 and GPL-2.0-or-later (mixed licensing)

# Open Format Smart Contracts

The Open Format Smart Contracts are the core of the Open Format ecosystem.

## Features

✅ Diamond proxy pattern

✅ ERC20 and ERC721A

✅ Creation, minting, transferring and burning functionality across multiple token types

✅ NFT lazy mint and drop mechanism

✅ NFT royalty support

✅ NFT Drop mechanism

✅ Reward mechanism

✅ Multi-chain support

✅ Multicall support

✅ Automated audit support

🔨 Revenue share mechanism

🔨 ERC-4626 - Tokenised vaults

## Getting Started

These instructions will give you a copy of the project up and running on your local machine for development and testing purposes.

## Installation

Install dependencies.

```
make install
```

Setup your environment variables.

```
cp .env.example .env
```

#### Environment variable configuration

| Variable      | Description                                                                                                              |
| ------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `PRIVATE_KEY` | Private key of wallet for deploying and interacting with scripts                                                         |
| `APP_ID`      | Used in scripts that engage with a particular app. An App ID can be created using the `CreateApp` script in the Makefile |

### Compile contracts

```
forge build
```

### Testing

```
forge test
```

### Deploying contracts locally

Create a local testnet node for deploying and testing smart contracts:

```
anvil
```

Deploy all contracts:

```
make deploy
```

Deploy an app:

```
make CreateApp args="hello-world"
```

See the [MakeFile](Makefile) for more commands.

## Formatting (vscode only)

To enable the built-in formatter that comes with Foundry to automatically format your code on save, you can add the following settings to your .vscode/settings.json:

```
{
  "editor.formatOnSave": true,
  "[solidity]": {
    "editor.defaultFormatter": "JuanBlanco.solidity"
  },
  "solidity.formatter": "forge",
}
```

## Static Analyzers

[Slither](https://github.com/crytic/slither) is a Solidity static analysis framework written in Python 3. It runs a suite of vulnerability detectors, prints visual information about contract details, and provides an API to easily write custom analyses. Slither enables developers to find vulnerabilities, enhance their code comprehension, and quickly prototype custom analyses.

```
slither .
```

[Mythril](https://github.com/ConsenSys/mythril) is a security analysis tool for EVM bytecode. It detects security vulnerabilities in smart contracts built for Ethereum, Hedera, Quorum, Vechain, Roostock, Tron and other EVM-compatible blockchains.

```
myth analyze src/*
```

## Code Style Guide

### Errors

Errors should be defined using [custom error syntax](https://blog.soliditylang.org/2021/04/21/custom-errors/) and follow the naming convention of `ContractName_errorDescriptionInCamelCase`.

for example:

```solidity
error ERC721LazyMint_insufficientLazyMintedTokens();
```

When testing the error, it's selector can be used:

```solidity
vm.expectRevert(ERC721LazyMint.ERC721LazyMint_insufficientLazyMintedTokens.selector);
```

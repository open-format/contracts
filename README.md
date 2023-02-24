# 📜 Open Format Contracts

**The main smart contracts used in the Open Format ecosystem**

## Getting Started

These instructions will give you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

## Installation

Install dependencies.

```
forge install & yarn install
```

Setup your environment variables.

```
cp .env.example .env
```

#### Environment variable configuration

| Variable                     | Description                                                                                                                                      |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `PRIVATE_KEY`                | Private key of wallet for deploying and interacting with scripts                                                                                 |
| `POLYGONSCAN_MUMBAI_API_KEY` | This is used for verifying contracts. You can generate a key for Mumbai testnet here - https://polygonscan.com/myapikey                          |
| `DIAMOND_CONTRACT_ADDRESS`   | This is used in the Makefile when running scripts that interact with a deployed diamond contract. e.g 0x86935f11c86623dec8a25696e1c19a8659cbf95d |

### Compile contracts

```
forge build
```

### Testing

```
forge test
```

### Formatting (vscode only)

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

### Static Analyzers

[Slither](https://github.com/crytic/slither) is a Solidity static analysis framework written in Python 3. It runs a suite of vulnerability detectors, prints visual information about contract details, and provides an API to easily write custom analyses. Slither enables developers to find vulnerabilities, enhance their code comprehension, and quickly prototype custom analyses.

```
slither .
```

[Mythril](https://github.com/ConsenSys/mythril) is a security analysis tool for EVM bytecode. It detects security vulnerabilities in smart contracts built for Ethereum, Hedera, Quorum, Vechain, Roostock, Tron and other EVM-compatible blockchains.

```
myth analyze src/*
```

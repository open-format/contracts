# @openformat/contracts

## 1.2.1

### Patch Changes

- [#114](https://github.com/open-format/contracts/pull/114) [`ec929a8`](https://github.com/open-format/contracts/commit/ec929a86302768a29e9d091598d06baceee7d5b4) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - Fix: Only return batchUri when calling tokenURI function on ERC721Base

## 1.2.0

### Minor Changes

- [#104](https://github.com/open-format/contracts/pull/104) [`a574791`](https://github.com/open-format/contracts/commit/a574791d034ac35b17386c3cd3c79bc336f71be9) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - - Adds ConstellationFactory and StarFactory
  - Refactor RewardsFacet to handle more use cases

### Patch Changes

- [#105](https://github.com/open-format/contracts/pull/105) [`c902bb3`](https://github.com/open-format/contracts/commit/c902bb36ba79eea42b7e09696637ed6751c47fa9) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - Adds endTimestamp to the ERC721LazyDrop claimConditions

## 1.1.0

### Minor Changes

- [#103](https://github.com/open-format/contracts/pull/103) [`2686467`](https://github.com/open-format/contracts/commit/268646731a4f975a6a6d625d69d49a01bc5eb056) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - add Ownable to ERC721 tokens

## 1.0.0

### Major Changes

- [#101](https://github.com/open-format/contracts/pull/101) [`615ca13`](https://github.com/open-format/contracts/commit/615ca13e638ff8e47a196b049baaf0435d2934a3) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - Release v1.0.0 🚀

## 0.1.0

### Minor Changes

- [#93](https://github.com/open-format/contracts/pull/93) [`6f9e914`](https://github.com/open-format/contracts/commit/6f9e9141c1fb87c476e196baaf879071f9531f17) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - - Deployments

- [#91](https://github.com/open-format/contracts/pull/91) [`b819a28`](https://github.com/open-format/contracts/commit/b819a28bf306c552669d7252899d88c1a5d1b505) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - token contracts now charge platform fee when minting

### Patch Changes

- [#92](https://github.com/open-format/contracts/pull/92) [`5affc38`](https://github.com/open-format/contracts/commit/5affc383f21afafc68d30583eac0ca793d015c93) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - add globals and platform fee info to settings

- [#85](https://github.com/open-format/contracts/pull/85) [`5fe672c`](https://github.com/open-format/contracts/commit/5fe672cd5b4b6074c555e1175e1978cfc368ee05) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - modify salt in factory contract

- [#94](https://github.com/open-format/contracts/pull/94) [`601b7f0`](https://github.com/open-format/contracts/commit/601b7f0f7e025910f0d89404337ac955236e6ee8) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - Adds reward facet contract

## 0.0.7

### Patch Changes

- [#72](https://github.com/open-format/contracts/pull/72) [`32a2e36`](https://github.com/open-format/contracts/commit/32a2e3606ca773b36a9ae565e5782d1af7d53912) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - improved deployment scripts

- [#73](https://github.com/open-format/contracts/pull/73) [`9d07e4e`](https://github.com/open-format/contracts/commit/9d07e4e281cb7a4e0430c8aa8a35591d47b96dda) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - add application access settings

- [#78](https://github.com/open-format/contracts/pull/78) [`8f38326`](https://github.com/open-format/contracts/commit/8f3832695744867d00ae33a3d21cda7a43f34186) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - erc20, erc721 factories now have internal salt

- [#76](https://github.com/open-format/contracts/pull/76) [`6da0e9d`](https://github.com/open-format/contracts/commit/6da0e9d2ed429bca907bcfc46bcf7d9c211c7944) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - tokens use access control, minter role granted to app on create

## 0.0.6

### Patch Changes

- [#64](https://github.com/open-format/contracts/pull/64) [`aa1fa3a`](https://github.com/open-format/contracts/commit/aa1fa3a9f5646f90b4d2b023bc49cd230f9cdd30) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - add lazy drop facet

## 0.0.5

### Patch Changes

- [#63](https://github.com/open-format/contracts/pull/63) [`8065799`](https://github.com/open-format/contracts/commit/8065799de8d5cdf55ea88cc4994b89a5bfac9e72) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - update error names

- [#61](https://github.com/open-format/contracts/pull/61) [`76177b1`](https://github.com/open-format/contracts/commit/76177b10ebef470a798435813faf53b57712137d) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - erc20 factory bug fixes

- [#58](https://github.com/open-format/contracts/pull/58) [`97de1f3`](https://github.com/open-format/contracts/commit/97de1f3d8aeda3039c19fdf8175c8db233d84190) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - factorys can create multiple implementations

## 0.0.4

### Patch Changes

- [#54](https://github.com/open-format/contracts/pull/54) [`6f83869`](https://github.com/open-format/contracts/commit/6f83869fcd7fdab0f9acd3a515613f23c697ad02) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - add lazy mint extension

- [#56](https://github.com/open-format/contracts/pull/56) [`39cdae1`](https://github.com/open-format/contracts/commit/39cdae1c7ac661db0f8707d1c6594d39b9aacb42) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - add erc721 lazy mint contract

## 0.0.3

### Patch Changes

- [#46](https://github.com/open-format/contracts/pull/46) [`af608cc`](https://github.com/open-format/contracts/commit/af608cccf0fd9b8a91fbf91cea894447f0d402c5) Thanks [@george-e-d-g-e](https://github.com/george-e-d-g-e)! - adds check for max percent when setting application fee

## 0.0.2

### Patch Changes

- [#41](https://github.com/open-format/contracts/pull/41) [`bf0ca3a`](https://github.com/open-format/contracts/commit/bf0ca3a69c71cba360c67c132701dc960c2006ed) Thanks [@tinypell3ts](https://github.com/tinypell3ts)! - Add changesets and github actions

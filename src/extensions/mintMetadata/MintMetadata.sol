// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {MintMetadataInternal} from "./MintMetadataInternal.sol";

/**
 *  @title   Mint Metadata
 *  @notice  The `MintMetadata` is a contract extension for any base NFT contract. It lets the smart contract
 *           using this extension set metadata for one nft at a time.
 *  @dev     This is derived from ThirdWeb's ERC721Base contract refactored as a module using the diamond storage pattern.
 *           storage and internal logic have been split out into seperate files
 */

abstract contract MintMetadata is MintMetadataInternal {
/// @dev all functions are internal see MintMetadataInternal.sol
}

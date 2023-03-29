// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ILazyMint} from "./ILazyMint.sol";
import {LazyMintInternal} from "./LazyMintInternal.sol";

/**
 *  @dev derived from third webs lazy mint extension but refactored to use diamond storage pattern and errors.
 *       Uses batchMintMetadata and keeps track of next token to lazy mint.
 *
 *  The `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

abstract contract LazyMint is ILazyMint, LazyMintInternal {}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

/**
 *  @dev derived from third webs lazy mint extension but refactored to use diamond storage pattern, errors and
 *       separate files for internal functions.
 *
 *  The `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

interface ILazyMint {
    /// @dev Emitted when tokens are lazy minted.
    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);

    error LazyMint_notAuthorizedToLazyMint();
    error LazyMint_zeroAmount();
}

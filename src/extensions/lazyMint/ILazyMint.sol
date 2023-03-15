// SPDX-License-Identifier: UNLICENSED
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

    /**
     *  @notice Lazy mints a given amount of NFTs.
     *
     *  @param amount           The number of NFTs to lazy mint.
     *
     *  @param baseURIForTokens The base URI for the 'n' number of NFTs being lazy minted, where the metadata for each
     *                          of those NFTs is the same.
     *
     *  @param extraData        Additional bytes data to be used at the discretion of the consumer of the contract.
     *
     *  @return batchId         A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(uint256 amount, string calldata baseURIForTokens, bytes calldata extraData)
        external
        returns (uint256 batchId);
}

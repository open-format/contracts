// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ILazyMint} from "./ILazyMint.sol";
import {LazyMintInternal} from "./LazyMintInternal.sol";
import {BatchMintMetadata} from "src/extensions/batchMintMetadata/BatchMintMetadata.sol";

/**
 *  @dev derived from third webs lazy mint extension but refactored to use diamond storage pattern and errors
 *
 *  The `LazyMint` is a contract extension for any base NFT contract. It lets you 'lazy mint' any number of NFTs
 *  at once. Here, 'lazy mint' means defining the metadata for particular tokenIds of your NFT contract, without actually
 *  minting a non-zero balance of NFTs of those tokenIds.
 */

abstract contract LazyMint is ILazyMint, LazyMintInternal, BatchMintMetadata {
    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The base URI for the 'n' number of NFTs being lazy minted, where the metadata for each
     *                           of those NFTs is `${baseURIForTokens}/${tokenId}`.
     *  @param _data             Additional bytes data to be used at the discretion of the consumer of the contract.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function lazyMint(uint256 _amount, string calldata _baseURIForTokens, bytes calldata _data)
        public
        virtual
        returns (uint256 batchId)
    {
        if (!_canLazyMint()) {
            revert Error_not_authorized();
        }

        if (_amount == 0) {
            revert Error_zero_amount();
        }

        uint256 startId = _getNextTokenIdToLazyMint();

        (uint256 nextTokenIdToMint, uint256 batchId) = _batchMintMetadata(startId, _amount, _baseURIForTokens);

        _setNextTokenIdToLazyMint(nextTokenIdToMint);

        emit TokensLazyMinted(startId, startId + _amount - 1, _baseURIForTokens, _data);

        return batchId;
    }

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);
}

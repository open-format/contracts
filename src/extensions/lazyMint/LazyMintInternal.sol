// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ILazyMint} from "./ILazyMint.sol";
import {LazyMintStorage} from "./LazyMintStorage.sol";
import {BatchMintMetadata} from "src/extensions/batchMintMetadata/BatchMintMetadata.sol";

abstract contract LazyMintInternal is ILazyMint, BatchMintMetadata {
    /**
     *  @notice                  Lets an authorized address lazy mint a given amount of NFTs.
     *
     *  @param _amount           The number of NFTs to lazy mint.
     *  @param _baseURIForTokens The base URI for the 'n' number of NFTs being lazy minted, where the metadata for each
     *                           of those NFTs is the same.
     *  @param _data             Additional bytes data to be used at the discretion of the consumer of the contract.
     *  @return batchId          A unique integer identifier for the batch of NFTs lazy minted together.
     */
    function _lazyMint(uint256 _amount, string calldata _baseURIForTokens, bytes calldata _data)
        internal
        virtual
        returns (uint256)
    {
        if (!_canLazyMint()) {
            revert LazyMint_notAuthorizedToLazyMint();
        }

        if (_amount == 0) {
            revert LazyMint_zeroAmount();
        }

        uint256 startId = _getNextTokenIdToLazyMint();

        (uint256 nextTokenIdToMint, uint256 batchId) = _batchMintMetadata(startId, _amount, _baseURIForTokens);

        _setNextTokenIdToLazyMint(nextTokenIdToMint);

        emit TokensLazyMinted(startId, startId + _amount - 1, _baseURIForTokens, _data);

        return batchId;
    }

    /// @dev Returns whether lazy minting can be performed in the given execution context.
    function _canLazyMint() internal view virtual returns (bool);

    function _getNextTokenIdToLazyMint() internal view virtual returns (uint256) {
        return LazyMintStorage.layout().nextTokenIdToLazyMint;
    }

    function _setNextTokenIdToLazyMint(uint256 id) internal virtual {
        LazyMintStorage.layout().nextTokenIdToLazyMint = id;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IBatchMintMetadata} from "./IBatchMintMetadata.sol";
import {BatchMintMetadataInternal} from "./BatchMintMetadataInternal.sol";

/**
 *  @title   Batch-mint Metadata
 *  @notice  The `BatchMintMetadata` is a contract extension for any base NFT contract. It lets the smart contract
 *           using this extension set metadata for `n` number of NFTs all at once. This is enabled by storing a single
 *           base URI for a batch of `n` NFTs, where the metadata for each NFT in a relevant batch is `baseURI/tokenId`.
 *  @dev     This is a copy of ThirdWeb's BatchMintMetadata extentension refactored to use diamond storage pattern.
 *           Interface, storage and internal logic have been split out into seperate files
 */

abstract contract BatchMintMetadata is IBatchMintMetadata, BatchMintMetadataInternal {
    /**
     *  @notice         Returns the count of batches of NFTs.
     *  @dev            Each batch of tokens has an in ID and an associated `baseURI`.
     *                  See {batchIds}.
     */
    function getBaseURICount() external view returns (uint256) {
        return _getBaseURICount();
    }

    /**
     *  @notice         Returns the ID for the batch of tokens the given tokenId belongs to.
     *  @dev            See {getBaseURICount}.
     *  @param _index   ID of a token.
     */
    function getBatchIdAtIndex(uint256 _index) external view returns (uint256) {
        return _getBatchIdAtIndex(_index);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {BatchMintMetadataStorage} from "./BatchMintMetadataStorage.sol";

abstract contract BatchMintMetadataInternal {
    function _getBaseURICount() internal view returns (uint256) {
        return BatchMintMetadataStorage.layout().batchIds.length;
    }
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    /// @dev Returns the id for the batch of tokens the given tokenId belongs to.

    function _getBatchId(uint256 _tokenId) internal view returns (uint256 batchId, uint256 index) {
        uint256 numOfTokenBatches = _getBaseURICount();
        uint256[] memory indices = BatchMintMetadataStorage.layout().batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                index = i;
                batchId = indices[i];

                return (batchId, index);
            }
        }

        revert("Invalid tokenId");
    }

    /**
     *  @notice         Returns the ID for the batch of tokens the given tokenId belongs to.
     *  @dev            See {getBaseURICount}.
     *  @param _index   ID of a token.
     */
    function _getBatchIdAtIndex(uint256 _index) public view returns (uint256) {
        if (_index >= _getBaseURICount()) {
            revert("Invalid index");
        }
        return BatchMintMetadataStorage.layout().batchIds[_index];
    }

    /// @dev Returns the baseURI for a token. The intended metadata URI for the token is baseURI + tokenId.
    function _getBaseURI(uint256 _tokenId) internal view returns (string memory) {
        BatchMintMetadataStorage.Layout storage l = BatchMintMetadataStorage.layout();

        uint256 numOfTokenBatches = _getBaseURICount();
        uint256[] memory indices = l.batchIds;

        for (uint256 i = 0; i < numOfTokenBatches; i += 1) {
            if (_tokenId < indices[i]) {
                return l.baseURI[indices[i]];
            }
        }

        revert("Invalid tokenId");
    }

    /// @dev Sets the base URI for the batch of tokens with the given batchId.
    function _setBaseURI(uint256 _batchId, string memory _baseURI) internal {
        BatchMintMetadataStorage.layout().baseURI[_batchId] = _baseURI;
    }

    /// @dev Mints a batch of tokenIds and associates a common baseURI to all those Ids.
    function _batchMintMetadata(uint256 _startId, uint256 _amountToMint, string memory _baseURIForTokens)
        internal
        returns (uint256 nextTokenIdToMint, uint256 batchId)
    {
        batchId = _startId + _amountToMint;
        nextTokenIdToMint = batchId;

        BatchMintMetadataStorage.Layout storage l = BatchMintMetadataStorage.layout();
        l.batchIds.push(batchId);
        l.baseURI[batchId] = _baseURIForTokens;
    }
}

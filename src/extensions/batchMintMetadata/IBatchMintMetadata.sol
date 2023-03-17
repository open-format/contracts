// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IBatchMintMetadata {
    error BatchMintMetadata_invalidTokenId();
    error BatchMintMetadata_invalidIndex();

    /**
     *  @notice         Returns the count of batches of NFTs.
     *  @dev            Each batch of tokens has an in ID and an associated `baseURI`.
     *                  See {batchIds}.
     */
    function getBaseURICount() external view returns (uint256);

    /**
     *  @notice         Returns the ID for the batch of tokens the given tokenId belongs to.
     *  @dev            See {getBaseURICount}.
     *  @param _index   ID of a token.
     */
    function getBatchIdAtIndex(uint256 _index) external view returns (uint256);
}

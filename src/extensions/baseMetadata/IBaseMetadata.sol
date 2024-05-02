// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

/**
 *  Thirdweb's `BaseMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *  for you contract.
 *
 *  Additionally, `BaseMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 */
interface IBaseMetadata {
    error BaseMetadata_notAuthorized();

    /// @dev Emitted when the contract URI is updated.
    event BaseURIUpdated(string prevURI, string newURI);

    /// @dev Returns the metadata URI of the contract.
    function baseURI() external view returns (string memory);
}

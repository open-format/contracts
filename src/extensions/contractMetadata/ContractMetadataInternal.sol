// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IContractMetadata} from "./IContractMetadata.sol";
import {ContractMetadataStorage} from "./ContractMetadataStorage.sol";

abstract contract ContractMetadataInternal is IContractMetadata {
    function _contractURI() internal view returns (string memory) {
        return ContractMetadataStorage.layout().contractURI;
    }

    /// @dev Lets a contract admin set the URI for contract-level metadata.
    function _setContractURI(string memory _uri) internal {
        ContractMetadataStorage.Layout storage l = ContractMetadataStorage.layout();
        string memory prevURI = l.contractURI;
        l.contractURI = _uri;

        emit IContractMetadata.ContractURIUpdated(prevURI, _uri);
    }
}

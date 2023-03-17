// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IContractMetadata} from "./IContractMetadata.sol";
import {ContractMetadataInternal} from "./ContractMetadataInternal.sol";

/**
 *  @title   Contract Metadata
 *  @notice  Thirdweb's `ContractMetadata` is a contract extension for any base contracts. It lets you set a metadata URI
 *           for you contract.
 *           Additionally, `ContractMetadata` is necessary for NFT contracts that want royalties to get distributed on OpenSea.
 *  @dev     This is a copy of ThirdWeb's ContractMetadata extension refactored to use diamond storage pattern.
 *           Interface, storage and internal logic have been split out into separate files
 *           https://github.com/thirdweb-dev/contracts/blob/main/contracts/extension/ContractMetadata.sol
 */

abstract contract ContractMetadata is IContractMetadata, ContractMetadataInternal {
    function contractURI() external view returns (string memory) {
        return _contractURI();
    }
    /**
     *  @notice         Lets a contract admin set the URI for contract-level metadata.
     *  @dev            Caller should be authorized to setup contractURI, e.g. contract admin.
     *                  See {_canSetContractURI}.
     *                  Emits {ContractURIUpdated Event}.
     *
     *  @param _uri     keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */

    function setContractURI(string memory _uri) external {
        if (!_canSetContractURI()) {
            revert ContractMetadata_notAuthorized();
        }

        _setContractURI(_uri);
    }

    /**
     *  @dev Returns whether contract metadata can be set in the given execution context.
     *       Needs to be overridden by any contract inheriting ContractMetadata
     */

    function _canSetContractURI() internal view virtual returns (bool);
}

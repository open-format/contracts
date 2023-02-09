// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @dev allocates space for baseURI
 */

library ContractMetadataStorage {
    struct Layout {
        string contractURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ContractURI");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

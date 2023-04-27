// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

/**
 * @dev allocates space for baseURI
 */

library BatchMintMetadataStorage {
    struct Layout {
        uint256[] batchIds;
        mapping(uint256 => string) baseURI;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.BatchMintMetadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

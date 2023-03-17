// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

library MintMetadataStorage {
    struct Layout {
        mapping(uint256 => string) tokenURIs;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.MintMetadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

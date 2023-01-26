// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library ReadableStorage {
    struct CachedFacet {
        address facet;
        uint256 timestamp;
    }

    struct Layout {
        mapping(bytes4 => CachedFacet) selectors;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.Readable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @dev gives Proxy contract ability to check storage for facet addresses
 * before looking up on Registry contract
 * @custom:wip this is experimental and may not make final
 */

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

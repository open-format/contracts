// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

library ApplicationAccessStorage {
    struct Layout {
        // TODO: change to merkle tree
        mapping(address => bool) approvedCreators;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ApplicationAccess");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

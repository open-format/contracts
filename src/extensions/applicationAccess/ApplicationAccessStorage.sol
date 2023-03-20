// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

library ApplicationAccessStorage {
    /**
     * @dev assuming the approved creators will change over time a simple
     *      mapping will be sufficient over a merkle tree implementation.
     */

    struct Layout {
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

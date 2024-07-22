// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ChargeStorage {
    struct Layout {
        mapping(address => uint256) minimumCreditBalance; // credit => minimum balance required to conduct actions.
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.Charge");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}
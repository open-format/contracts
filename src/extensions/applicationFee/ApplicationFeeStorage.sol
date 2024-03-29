// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ApplicationFeeStorage {
    struct Layout {
        uint16 percentageBPS;
        address recipient;
        mapping(address => bool) acceptedCurrencies;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ApplicationFee");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

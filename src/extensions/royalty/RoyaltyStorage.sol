// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

library RoyaltyStorage {
    struct RoyaltyInfo {
        address recipient;
        uint16 bps;
    }

    struct Layout {
        address royaltyRecipient;
        uint16 royaltyBps;
        mapping(uint256 => RoyaltyInfo) royaltyInfoForToken;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.Royalty");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

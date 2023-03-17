// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

library LazyMintStorage {
    struct Layout {
        // The tokenId assigned to the next new NFT to be lazy minted.
        uint256 nextTokenIdToLazyMint;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.LazyMint");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

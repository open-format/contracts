// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ERC721FactoryStorage {
    struct Layout {
        mapping(address => uint256) contractCount; // account => number of contracts created
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ERC721Factory");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

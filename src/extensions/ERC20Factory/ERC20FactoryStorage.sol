// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

library ERC20FactoryStorage {
    struct Layout {
        mapping(bytes32 => address) ERC20Contracts; // salt => id
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ERC20Factory");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

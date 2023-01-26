// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library UpgradableStorage {
    struct Layout {
        address registryAddress;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.Upgradable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

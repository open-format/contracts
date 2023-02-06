// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library InitializableStorage {
    struct Layout {
        /**
         * @dev Indicates that the contract has been initialized.
         * @custom:oz-retyped-from bool
         */
        uint8 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.Initializable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @dev allocates space for baseURI
 */

library ApplicationFeeStorage {
    enum FeeMethod {
        NONE,
        SPECIFIC,
        RELATIVE
    }

    struct Layout {
        uint256 base;
        uint16 percentageBPS;
        address recipient;
        FeeMethod feeMethod;
        address specificToken;
        mapping(address => bool) acceptedTokens;
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

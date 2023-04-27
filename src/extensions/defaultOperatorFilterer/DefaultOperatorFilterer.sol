// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {DefaultOperatorFiltererInternal} from "./DefaultOperatorFiltererInternal.sol";
import {DEFAULT_SUBSCRIPTION} from "./DefaultOperatorFiltererConstants.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 * @dev    This is derived from openseas OperatorFilterer.sol but refactored to be compatible with diamond pattern
 *         The constructor has been replaced with an innit function special care must be taken to ensure this is
 *         called in the intilizer of any inheriting contract
 */
abstract contract DefaultOperatorFilterer is DefaultOperatorFiltererInternal {
    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ERC20Factory} from "../extensions/ERC20Factory/ERC20Factory.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {ApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";

/**
 * @title   "ERC20Factory Facet"
 * @notice  A facet of the ERC20Factory contract that provides functionality for creating new ERC20 tokens.
 *          This contract also includes extensions for Ownable, PlatformFee, and ApplicationAccess, which allow for ownership management,
 *          platform fee collection, and restricted access to contract creation, respectively.
 *          Before creating a new contract, a platform fee is added, which must be paid in ether.
 */

contract ERC20FactoryFacet is ERC20Factory, Ownable, PlatformFee, ApplicationAccess {
    /**
     * @dev uses applicationAccess extension for create access for new erc20 contracts
     */
    function _canCreate() internal view override returns (bool) {
        return _hasCreatorAccess(msg.sender);
    }

    /**
     * @dev override before create to add platform fee
     *      requires msg.value to be equal or more than base platform fee
     *      when calling createERC20
     */
    function _beforeCreate() internal override {
        (address recipient, uint256 amount) = _platformFeeInfo(0);

        if (amount == 0) {
            return;
        }

        // ensure the ether being sent was included in the transaction
        if (msg.value < amount) {
            revert CurrencyTransferLib.CurrencyTransferLib_insufficientValue();
        }

        CurrencyTransferLib.safeTransferNativeToken(recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }
}

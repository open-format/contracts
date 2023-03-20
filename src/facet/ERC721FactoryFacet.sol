// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {ERC721Factory} from "../extensions/ERC721Factory/ERC721Factory.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";

/**
 * @title   "ERC721Factory Facet"
 * @notice  (WIP)
 */

contract ERC721FactoryFacet is ERC721Factory, Ownable, PlatformFee, ApplicationAccess {
    /**
     * @dev uses applicationAccess extension for create access for new erc721 contracts
     */
    function _canCreate() internal view override returns (bool) {
        return _hasCreatorAccess(msg.sender);
    }

    /**
     * @dev override before create to add platform fee
     *      requires msg.value to be equal or more than base platform fee
     *      when calling createERC721
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

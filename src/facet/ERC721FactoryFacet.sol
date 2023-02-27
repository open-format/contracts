// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ERC721Factory} from "../extensions/ERC721Factory/ERC721Factory.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";

/**
 * @title   "ERC721Factory Facet"
 * @notice  (WIP)
 */

contract ERC721FactoryFacet is ERC721Factory, PlatformFee, Ownable {
    /**
     * @dev sets permissions to create new nft to proxy app owner
     */
    function _canCreate() internal view override returns (bool) {
        return msg.sender == _owner();
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
            revert Error_insufficientValue();
        }

        CurrencyTransferLib.transferCurrency(address(0), msg.sender, recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }
}

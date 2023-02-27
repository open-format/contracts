// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ERC20Factory} from "../extensions/ERC20Factory/ERC20Factory.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";

/**
 * @title   "ERC20Factory Facet"
 * @notice  (WIP)
 */

contract ERC20FactoryFacet is ERC20Factory, Ownable, PlatformFee {
    /*
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
            revert CurrencyTransferLib.Error_insufficientValue();
        }

        CurrencyTransferLib.safeTransferNativeToken(recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }
}

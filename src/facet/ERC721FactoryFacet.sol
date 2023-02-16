// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC721Factory} from "../extensions/ERC721Factory/ERC721Factory.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";

/**
 * @title   "ERC721Factory Facet"
 * @notice  (WIP)
 */

contract ERC721FactoryFacet is ERC721Factory, PlatformFee, Ownable {
    /**
     * @dev sets permmisions to create new nft to proxy app owner
     */
    function _canCreate() internal view override returns (bool) {
        return msg.sender == _owner();
    }

    /**
     * @dev override before create to add platform fee
     *      requires msg.value to be equal or more than base platfrom fee
     *      when calling createERC721
     */
    function _beforeCreate() internal override {
        _payPlatfromFee(0);
    }
}

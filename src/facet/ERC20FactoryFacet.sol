// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC20Factory} from "../extensions/ERC20Factory/ERC20Factory.sol";

/**
 * @title   "ERC20Factory Facet"
 * @notice  (WIP)
 */

contract ERC20FactoryFacet is ERC20Factory, Ownable {
    /*
    * @dev sets permissions to create new nft to proxy app owner
    */
    function _canCreate() internal view override returns (bool) {
        return msg.sender == _owner();
    }
}

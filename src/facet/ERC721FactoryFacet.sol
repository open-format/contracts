// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC721Factory} from "../extensions/ERC721Factory/ERC721Factory.sol";

/**
 * @title   "ERC721Factory Facet"
 * @notice  (WIP)
 */

contract ERC721FactoryFacet is ERC721Factory, Ownable {
    /*
    * @dev sets permmisions to create new nft to proxy app owner
    */
    function _canCreate() internal view override returns (bool) {
        return msg.sender == _owner();
    }
}

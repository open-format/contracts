// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
/**
 * @title Open Format Globals
 * @notice holds all global variables that need to be shared between all proxy apps
 * @dev facets can access global variables by calling this contract. see the `extensions/global`
 *      for example:
 *      ```solidity
 *           import {Globals} from "./global/Globals.sol";
 *
 *           //...inside a function
 *
 *           address ERC721Iplementation = Globals(GlobalStorage.layout().globals).ERC721Implementation();
 *      ```
 * @dev Note: if this is deployed behind an upgradable proxy the global variabls can be added to
 */

contract Globals is Ownable {
    address public ERC721Implementation;

    constructor() {
        _setOwner(msg.sender);
    }

    function setERC721Implementation(address _implementation) public onlyOwner {
        ERC721Implementation = _implementation;
    }
}

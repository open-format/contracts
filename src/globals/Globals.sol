// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
/**
 * @title Globals
 * @notice holds all global variables that need to be shared between all proxy apps
 * @dev facets can access global variables by calling this contract via `extensions/global`
 *      for example:
 *      ```solidity
 *             import {Global} from "./extensions/Global.sol";
 *
 *             contract Example is Global {
 *                 exampleFunction() {
 *                     address ERC721Iplementation = _getGlobals.ERC721Implementation();
 *                 }
 *
 *             }
 *         ```
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

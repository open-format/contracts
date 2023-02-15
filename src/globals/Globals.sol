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
    address public ERC20Implementation;

    uint256 public baseFee;
    address payable public baseFeeReciever;

    constructor() {
        _setOwner(msg.sender);
    }

    function setERC721Implementation(address _implementation) public onlyOwner {
        ERC721Implementation = _implementation;
    }

    function setERC20Implementation(address _implementation) public onlyOwner {
        ERC20Implementation = _implementation;
    }

    function setBaseFee(uint256 _baseFee) public onlyOwner {
        baseFee = _baseFee;
    }

    function setBaseFeeReciver(address payable _baseFeeReciever) public onlyOwner {
        baseFeeReciever = _baseFeeReciever;
    }

    function baseFeeInfo() external view returns (uint256 amount, address payable reciever) {
        amount = baseFee;
        reciever = baseFeeReciever;
    }
}

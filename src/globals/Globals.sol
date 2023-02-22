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
 *                     address ERC721Implementation = _getGlobals.ERC721Implementation();
 *                 }
 *
 *             }
 *         ```
 * @dev Note: if this is deployed behind an upgradable proxy the global variables can be added to
 */

contract Globals is Ownable {
    address public ERC721Implementation;
    address public ERC20Implementation;

    error ERROR_percentageFeeCannotExceed100();

    struct PlatformFee {
        uint256 base;
        uint16 percentageBPS;
        address recipient;
    }

    PlatformFee platformFee;

    constructor() {
        _setOwner(msg.sender);
    }

    function setERC721Implementation(address _implementation) public onlyOwner {
        ERC721Implementation = _implementation;
    }

    function setERC20Implementation(address _implementation) public onlyOwner {
        ERC20Implementation = _implementation;
    }

    function setPlatformFee(uint256 _base, uint16 _percentageBPS, address recipient) public onlyOwner {
        if (_percentageBPS > 10_000) {
            revert ERROR_percentageFeeCannotExceed100();
        }
        platformFee = PlatformFee(_base, _percentageBPS, recipient);
    }

    function setPlatformBaseFee(uint256 _base) public onlyOwner {
        platformFee.base = _base;
    }

    function setPlatformPercentageFee(uint16 _percentageBPS) public onlyOwner {
        if (_percentageBPS > 10_000) {
            revert ERROR_percentageFeeCannotExceed100();
        }
        platformFee.percentageBPS = _percentageBPS;
    }

    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 fee) {
        recipient = platformFee.recipient;
        fee = (_price > 0) ? platformFee.base + (_price * platformFee.percentageBPS) / 10_000 : platformFee.base;
    }
}

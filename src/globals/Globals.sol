// SPDX-License-Identifier: Apache-2.0
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
    error Globals_percentageFeeCannotExceed100();

    event ERC721ImplementationUpdated(bytes32 _implementationId, address _implementation);
    event ERC20ImplementationUpdated(bytes32 _implementationId, address _implementation);

    struct PlatformFee {
        uint256 base;
        uint16 percentageBPS;
        address recipient;
    }

    mapping(bytes32 => address) ERC721Implementations;
    mapping(bytes32 => address) ERC20Implementations;

    PlatformFee platformFee;

    constructor() {
        _setOwner(msg.sender);
    }

    function setERC721Implementation(bytes32 _implementationId, address _implementation) public onlyOwner {
        ERC721Implementations[_implementationId] = _implementation;
        emit ERC721ImplementationUpdated(_implementationId, _implementation);
    }

    function getERC721Implementation(bytes32 _implementationId) public view returns (address) {
        return ERC721Implementations[_implementationId];
    }

    function setERC20Implementation(bytes32 _implementationId, address _implementation) public onlyOwner {
        ERC20Implementations[_implementationId] = _implementation;
        emit ERC20ImplementationUpdated(_implementationId, _implementation);
    }

    function getERC20Implementation(bytes32 _implementationId) public view returns (address) {
        return ERC20Implementations[_implementationId];
    }

    function setPlatformFee(uint256 _base, uint16 _percentageBPS, address recipient) public onlyOwner {
        if (_percentageBPS > 10_000) {
            revert Globals_percentageFeeCannotExceed100();
        }
        platformFee = PlatformFee(_base, _percentageBPS, recipient);
    }

    function setPlatformBaseFee(uint256 _base) public onlyOwner {
        platformFee.base = _base;
    }

    function setPlatformPercentageFee(uint16 _percentageBPS) public onlyOwner {
        if (_percentageBPS > 10_000) {
            revert Globals_percentageFeeCannotExceed100();
        }
        platformFee.percentageBPS = _percentageBPS;
    }

    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 fee) {
        recipient = platformFee.recipient;
        fee = (_price > 0) ? platformFee.base + (_price * platformFee.percentageBPS) / 10_000 : platformFee.base;
    }
}

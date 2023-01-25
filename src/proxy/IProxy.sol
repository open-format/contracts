// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {ISafeOwnable} from "@solidstate/contracts/access/ownable/ISafeOwnable.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IDiamondBase} from "@solidstate/contracts/proxy/diamond/base/IDiamondBase.sol";
import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";

interface IProxy is IDiamondBase, IDiamondReadable, ISafeOwnable, IERC165 {
    error FunctionSelectorNotFound();
    error FunctionCallReverted();

    receive() external payable;
}

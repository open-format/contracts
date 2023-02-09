// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC20Base} from "./ERC20Base.sol";

contract ERC20BaseMock is ERC20Base {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) payable initializer {
        initialize(_name, _symbol, _decimals, _supply);
    }
}

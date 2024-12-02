// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC20Point} from "./ERC20Point.sol";

contract ERC20PointMock is ERC20Point {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) payable initializer {
        initialize(msg.sender, _name, _symbol, _decimals, _supply, "");
    }
}

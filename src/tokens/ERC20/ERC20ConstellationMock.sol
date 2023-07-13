// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC20Constellation} from "./ERC20Constellation.sol";

contract ERC20ConstellationMock is ERC20Constellation {
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) payable initializer {
        initialize(msg.sender, _name, _symbol, _decimals, _supply, "");
    }
}

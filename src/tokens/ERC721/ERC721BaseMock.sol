// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721Base} from "./ERC721Base.sol";

contract ERC721BaseMock is ERC721Base {
    constructor(string memory name_, string memory symbol_) payable initializerERC721A {
        __ERC721A_init(name_, symbol_);
    }
}

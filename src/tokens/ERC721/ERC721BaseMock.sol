// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ERC721Base} from "./ERC721Base.sol";

contract ERC721BaseMock is ERC721Base {
    constructor(string memory _name, string memory _symbol, address _royaltyReciever, uint16 _royaltyBPS)
        payable
        initializerERC721A
    {
        initialize(msg.sender, _name, _symbol, _royaltyReciever, _royaltyBPS);
    }
}

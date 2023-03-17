// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ERC721LazyMint} from "./ERC721LazyMint.sol";

contract ERC721LazyMintMock is ERC721LazyMint {
    constructor(string memory _name, string memory _symbol, address _royaltyReceiver, uint16 _royaltyBPS)
        ERC721LazyMint(true)
    {
        initialize(msg.sender, _name, _symbol, _royaltyReceiver, _royaltyBPS);
    }
}

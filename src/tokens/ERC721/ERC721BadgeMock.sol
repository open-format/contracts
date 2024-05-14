// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC721Badge} from "./ERC721Badge.sol";

contract ERC721BadgeMock is ERC721Badge {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyReceiver,
        uint16 _royaltyBPS,
        bytes memory _data
    ) ERC721Badge(true) {
        initialize(msg.sender, _name, _symbol, _royaltyReceiver, _royaltyBPS, _data);
    }
}

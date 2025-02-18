// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC721BadgeNonTransferable} from "./ERC721BadgeNonTransferable.sol";

contract ERC721BadgeNonTransferableMock is ERC721BadgeNonTransferable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyReceiver,
        uint16 _royaltyBPS,
        bytes memory _data
    ) ERC721BadgeNonTransferable(true) {
        initialize(msg.sender, _name, _symbol, _royaltyReceiver, _royaltyBPS, _data);
    }
}

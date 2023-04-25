// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC721LazyMint} from "./ERC721LazyMint.sol";

contract ERC721LazyMintMock is ERC721LazyMint {
    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyReceiver,
        uint16 _royaltyBPS,
        bytes memory _data
    ) ERC721LazyMint(true) {
        initialize(msg.sender, _name, _symbol, _royaltyReceiver, _royaltyBPS, _data);
    }

    /* STORAGE HELPERS */

    function _globals() external view returns (address) {
        return _getGlobalsAddress();
    }
}

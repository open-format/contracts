// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ILazyMint} from "./ILazyMint.sol";
import {LazyMint} from "./LazyMint.sol";

contract LazyMintMock is LazyMint {
    address public minter;

    constructor(address _minter) {
        minter = _minter;
    }

    /// @dev override to test permissions
    function _canLazyMint() internal view virtual override returns (bool) {
        return msg.sender == minter;
    }

    /* INTERNAL HELPERS */

    function nextTokenIdToLazyMint() external view returns (uint256) {
        return _getNextTokenIdToLazyMint();
    }

    /// @dev exposes getBaseURI from batchMetadata extension
    function getBaseURI(uint256 _tokenId) external view returns (string memory) {
        return _getBaseURI(_tokenId);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ILazyMint} from "./ILazyMint.sol";
import {LazyMint} from "./LazyMint.sol";

contract LazyMintMock is LazyMint {
    address public minter;

    constructor(address _minter) {
        minter = _minter;
    }

    function lazyMint(uint256 _amount, string calldata _baseURIForTokens, bytes calldata _data)
        external
        returns (uint256)
    {
        return _lazyMint(_amount, _baseURIForTokens, _data);
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

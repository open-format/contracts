// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {MintMetadataStorage} from "./MintMetadataStorage.sol";

abstract contract MintMetadataInternal {
    /// @dev Returns the tokenURI for a token, will return empty string if not set
    function _getTokenURI(uint256 _tokenId) internal view returns (string memory) {
        return MintMetadataStorage.layout().tokenURIs[_tokenId];
    }

    /// @dev Mints a single tokenId and stores it's token URI
    function _mintMetadata(uint256 _tokenId, string memory _tokenURI) internal virtual {
        MintMetadataStorage.Layout storage l = MintMetadataStorage.layout();

        require(bytes(l.tokenURIs[_tokenId]).length == 0, "URI already set");
        l.tokenURIs[_tokenId] = _tokenURI;
    }
}

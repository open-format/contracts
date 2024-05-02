// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IBaseMetadata} from "./IBaseMetadata.sol";
import {BaseMetadataStorage} from "./BaseMetadataStorage.sol";

abstract contract BaseMetadataInternal is IBaseMetadata {
    function _baseURI() internal view virtual returns (string memory) {
        return BaseMetadataStorage.layout().baseURI;
    }

    function _setBaseURI(string memory _uri) internal virtual {
        BaseMetadataStorage.Layout storage l = BaseMetadataStorage.layout();
        string memory prevURI = l.baseURI;
        l.baseURI = _uri;

        emit IBaseMetadata.BaseURIUpdated(prevURI, _uri);
    }
}

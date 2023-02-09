// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721FactoryStorage} from "./ERC721FactoryStorage.sol";
import {Global} from "../../extensions/global/Global.sol";

abstract contract ERC721FactoryInternal is Global {
    function _getId(bytes32 _salt) internal view virtual returns (address) {
        return ERC721FactoryStorage.layout().ERC721Contracts[_salt];
    }

    function _setId(bytes32 _salt, address _id) internal virtual {
        ERC721FactoryStorage.layout().ERC721Contracts[_salt] = _id;
    }

    function _getImplementation() internal view returns (address) {
        return _getGlobals().ERC721Implementation();
    }

    function _canCreate() internal view virtual returns (bool);
}

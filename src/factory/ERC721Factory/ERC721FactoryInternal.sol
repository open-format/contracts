// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721FactoryStorage} from "./ERC721FactoryStorage.sol";
import {Global} from "../../extensions/global/Global.sol";

abstract contract ERC721FactoryInternal is Global {
    function _getDeployment(bytes32 _salt) internal view virtual returns (address) {
        return ERC721FactoryStorage.layout().ERC721Contracts[_salt];
    }

    function _setDeployment(bytes32 _salt, address _deployment) internal virtual {
        ERC721FactoryStorage.layout().ERC721Contracts[_salt] = _deployment;
    }

    function _getImplementation() internal view returns (address) {
        return _getGlobals().ERC721Implementation();
    }
}

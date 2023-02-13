// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC20FactoryStorage} from "./ERC20FactoryStorage.sol";
import {Global} from "../../extensions/global/Global.sol";

abstract contract ERC20FactoryInternal is Global {
    function _getId(bytes32 _salt) internal view virtual returns (address) {
        return ERC20FactoryStorage.layout().ERC20Contracts[_salt];
    }

    function _setId(bytes32 _salt, address _id) internal virtual {
        ERC20FactoryStorage.layout().ERC20Contracts[_salt] = _id;
    }

    function _getImplementation() internal view returns (address) {
        return _getGlobals().ERC20Implementation();
    }

    function _canCreate() internal view virtual returns (bool);
}

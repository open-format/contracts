// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Globals} from "../../globals/Globals.sol";
import {GlobalStorage} from "./GlobalStorage.sol";

abstract contract GlobalInternal {
    function _getGlobals() internal view returns (Globals) {
        return Globals(GlobalStorage.layout().globals);
    }

    function _getGlobalsAddress() internal view returns (address) {
        return GlobalStorage.layout().globals;
    }

    function _setGlobals(address _globals) internal {
        GlobalStorage.layout().globals = _globals;
    }
}

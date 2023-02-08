// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Globals} from "../../globals/Globals.sol";
import {GlobalStorage} from "./GlobalStorage.sol";

abstract contract GlobalInternal {
    /**
     * @dev returns Globals contract so inherited contracts can call without the need to explicitly import Globals
     */
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

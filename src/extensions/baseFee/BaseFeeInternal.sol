// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Global} from "../global/Global.sol";

abstract contract BaseFeeInternal is Global {
    /**
     * @dev returns base fee from globals contract
     */
    function _getBaseFeeInfo() internal view returns (uint256, address payable) {
        return _getGlobals().baseFeeInfo();
    }
}

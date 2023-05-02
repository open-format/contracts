// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Global} from "../global/Global.sol";
import {IPlatformFee} from "./IPlatformFee.sol";

abstract contract PlatformFeeInternal is IPlatformFee, Global {
    /**
     * @dev wrapper that calls platformFeeInfo from globals contract
     *      inspired by eip-2981 NFT royalty standard
     */
    function _platformFeeInfo(uint256 _price) internal view returns (address recipient, uint256 amount) {
        (recipient, amount) = _getGlobals().platformFeeInfo(_price);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IPlatformFee} from "./IPlatformFee.sol";
import {PlatformFeeInternal} from "./PlatformFeeInternal.sol";

abstract contract PlatformFee is IPlatformFee, PlatformFeeInternal {
    /**
     *   @inheritdoc IPlatformFee
     */
    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount) {
        (recipient, amount) = _platformFeeInfo(_price);
    }
}

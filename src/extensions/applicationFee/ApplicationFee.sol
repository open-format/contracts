// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeInternal} from "./ApplicationFeeInternal.sol";

abstract contract ApplicationFee is IApplicationFee, ApplicationFeeInternal {
    function applicationFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount) {
        return _applicationFeeInfo(_price);
    }
}

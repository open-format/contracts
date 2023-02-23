// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeInternal} from "./ApplicationFeeInternal.sol";

/**
 * @dev The application fee extension can be used by facets to set and pay a percentage fee.
 *
 *      inheriting contracts can use _payApplicationFee internal function to pay in ether or erc20 tokens.
 *      strongly advised to use a reentry guard.
 */

abstract contract ApplicationFee is IApplicationFee, ApplicationFeeInternal {
    /**
     *   @inheritdoc IApplicationFee
     */
    function applicationFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount) {
        return _applicationFeeInfo(_price);
    }
}

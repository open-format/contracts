// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeInternal} from "./ApplicationFeeInternal.sol";

/**
 * @dev The application fee extension can be used by facets to set and pay a percentage fee.
 *
 *      inheriting contracts can use the internal function _applicationFeeInfo to get the amount
 *      and recipient to pay.
 *
 *      See payApplicationFee in ApplicationFeeMock.sol for an implementation example.
 */

abstract contract ApplicationFee is IApplicationFee, ApplicationFeeInternal {
    modifier onlyAcceptedCurrencies(address _currency) {
        if (!_isCurrencyAccepted(_currency)) {
            revert Error_currency_not_accepted();
        }
        _;
    }

    /**
     *   @inheritdoc IApplicationFee
     */

    function applicationFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount) {
        return _applicationFeeInfo(_price);
    }
}

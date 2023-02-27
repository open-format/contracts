// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

abstract contract ApplicationFeeInternal is IApplicationFee {
    /**
     * @dev gets applicationFeeInfo for a given price based on percentBPS
     *      inspired by eip-2981 NFT royalty standard
     */
    function _applicationFeeInfo(uint256 _price) internal view returns (address recipient, uint256 amount) {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        recipient = l.recipient;
        amount = _price == 0 ? 0 : (_price * l.percentageBPS) / 10_000;
    }

    function _setApplicationFee(uint16 _percentBPS, address _recipient) internal virtual {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        l.percentageBPS = _percentBPS;
        l.recipient = _recipient;
    }

    function _setAcceptedCurrencies(address[] memory _currencies, bool[] memory _approvals) internal virtual {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        if (_currencies.length != _approvals.length) {
            revert Error_currencies_and_approvals_must_be_the_same_length();
        }

        for (uint256 i = 0; i < _currencies.length; i++) {
            l.acceptedCurrencies[_currencies[i]] = _approvals[i];
        }
    }

    function _isCurrencyAccepted(address _currency) internal virtual returns (bool) {
        return ApplicationFeeStorage.layout().acceptedCurrencies[_currency];
    }
}

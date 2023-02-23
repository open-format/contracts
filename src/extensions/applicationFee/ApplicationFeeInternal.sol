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

    /**
     * @dev sends ether to recipient
     *      inspired by openzepplin Address.sendValue
     *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     */
    function _sendValue(address recipient, uint256 amount) internal virtual {
        if (address(this).balance < amount) {
            revert Error_insufficientBalance();
        }

        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert Error_unableToSendValue();
        }
    }

    function _handleNativePayment(address _to, uint256 _amount) internal virtual {
        // ensure the ether being sent was included in the transaction
        if (msg.value < _amount) {
            revert Error_insufficientValue();
        }

        if (_amount > 0) {
            _sendValue(_to, _amount);

            emit PaidApplicationFee(address(0), _amount);
        }
    }

    /**
     * @dev derived from third web CurrencyTransferLib
     *      https://github.com/thirdweb-dev/contracts/blob/51d459e3f00690db09bbb8f6b9f0fba3aa025b8d/contracts/lib/CurrencyTransferLib.sol#L64
     */

    function _handleTokenPayment(address _currency, address _from, address _to, uint256 _amount) internal virtual {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            SafeERC20.safeTransfer(IERC20(_currency), _to, _amount);
        } else {
            SafeERC20.safeTransferFrom(IERC20(_currency), _from, _to, _amount);
        }

        emit PaidApplicationFee(_currency, _amount);
    }

    /**
     * @dev              pays application fee in ether or erc20 token, to be used in payable functions
     * @param _price     used to calculate application fee, can be set to 0 for none priced functions
     * @return remaining is the remaining balance after the application fee has been paid
     */

    function _payApplicationFee(address _currency, uint256 _price) internal virtual returns (uint256 remaining) {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        // check currency accepted
        if (!l.acceptedCurrencies[_currency]) {
            revert Error_currency_not_accepted();
        }

        (address recipient, uint256 amount) = _applicationFeeInfo(_price);

        if (amount == 0) {
            return _price;
        }

        if (_currency == address(0)) {
            _handleNativePayment(recipient, amount);
            return _price - amount;
        } else {
            _handleTokenPayment(_currency, _payer(), recipient, amount);
            return _price - amount;
        }
    }

    /**
     * @dev override to change which address makes the application fee payment
     */

    function _payer() internal virtual returns (address) {
        return msg.sender;
    }
}

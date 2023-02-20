// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IApplicationFee} from "./IApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

abstract contract ApplicationFeeInternal is IApplicationFee {
    /**
     * @dev wrapper that calls platformFeeInfo from globals contract
     *      inspired by eip-2981 NFT royalty standard
     */
    function _applicationFeeInfo(uint256 _price) internal view returns (address recipient, uint256 amount) {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        recipient = l.recipient;
        amount = (_price > 0) ? l.base + (_price * l.percentageBPS) / 10_000 : l.base;
    }

    function _setApplicationFee(uint256 _base, uint16 _percentBPS, address _recipient) internal virtual {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        l.base = _base;
        l.percentageBPS = _percentBPS;
        l.recipient = _recipient;
    }

    function _setFeeMethod(ApplicationFeeStorage.FeeMethod _method) internal virtual {
        ApplicationFeeStorage.layout().feeMethod = _method;
    }

    function _setSpecificToken(address _token) internal virtual {
        ApplicationFeeStorage.layout().specificToken = _token;
    }

    function _setAcceptedTokens(address[] memory _tokens, bool[] memory _approval) internal virtual {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();
        // TODO: change to error if this implementation is good enough
        require(_tokens.length == _approval.length, "tokens and approvals must be the same length");

        for (uint256 i = 0; i < _tokens.length; i++) {
            l.acceptedTokens[_tokens[i]] = _approval[i];
        }
    }

    /**
     * @dev sends ether to recpient
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
     * @dev              pays platform fee in ether, to be used in payable functions
     * @param _price     used to calculate platfrom fee, can be set to 0 for none priced functions
     * @return remaining is the remaining ether balance after the platform fee has been paid
     */

    function _payApplicationFee(address _currency, uint256 _price) internal virtual returns (uint256 remaining) {
        ApplicationFeeStorage.Layout storage l = ApplicationFeeStorage.layout();

        // check fee accepted
        if (l.feeMethod == ApplicationFeeStorage.FeeMethod.NONE) {
            return _price;
        }

        // handle payment for specific token
        if (l.feeMethod == ApplicationFeeStorage.FeeMethod.SPECIFIC) {
            // check currency accepted
            if (_currency != l.specificToken) {
                revert("currency not accepted");
            }

            (address recipient, uint256 amount) = _applicationFeeInfo(_price);

            if (amount == 0) {
                return _price;
            }

            if (_currency == address(0)) {
                _handleNativePayment(recipient, amount);
                return _price - amount;
            } else {
                // TODO: handleERC20Payment

                // just return price for now
                return _price;
            }
        }

        // handle payment for relative token
        if (l.feeMethod == ApplicationFeeStorage.FeeMethod.RELATIVE) {
            // check currency accepted
            if (!l.acceptedTokens[_currency]) {
                revert("currency not accepted");
            }

            (address recipient, uint256 amount) = _applicationFeeInfo(_price);

            if (amount == 0) {
                return _price;
            }

            if (_currency == address(0)) {
                _handleNativePayment(recipient, amount);
                return _price - amount;
            } else {
                // TODO: handleERC20Payment

                // just return price for now
                return _price;
            }
        }
    }
}

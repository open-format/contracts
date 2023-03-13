// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721Drop, IERC721Drop} from "src/extensions/ERC721Drop/ERC721Drop.sol";
import {ERC721DropStorage} from "src/extensions/ERC721Drop/ERC721DropStorage.sol";

import {PlatformFee} from "src/extensions/platformFee/PlatformFee.sol";
import {ApplicationFee} from "src/extensions/applicationFee/ApplicationFee.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

contract ERC721DropFacet is ERC721Drop, PlatformFee, ApplicationFee {
    /**
     * @dev override before setClaimCondition to add platform fee
     *      requires msg.value to be equal or more than base platform fee
     *      when calling setClaimCondition
     */
    function _beforeSetClaimCondition(ERC721DropStorage.ClaimCondition calldata _condition) internal override {
        (address recipient, uint256 amount) = _platformFeeInfo(0);

        if (amount == 0) {
            return;
        }

        // ensure the ether being sent was included in the transaction
        if (msg.value < amount) {
            revert CurrencyTransferLib.Error_insufficientValue();
        }

        CurrencyTransferLib.safeTransferNativeToken(recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }

    function _collectPriceOnClaim(address _tokenContract, uint256 _quantity, address _currency, uint256 _pricePerToken)
        internal
        override
        onlyAcceptedCurrencies(_currency)
    {
        // TODO: is this at risk of overflow?
        uint256 totalPrice = _quantity * _pricePerToken;
        (address platformFeeRecipient, uint256 platformFee) = _platformFeeInfo(totalPrice);
        (address applicationFeeRecipient, uint256 applicationFee) = _applicationFeeInfo(totalPrice);

        bool isNativeToken = _currency == CurrencyTransferLib.NATIVE_TOKEN;
        uint256 fees = isNativeToken ? platformFee + applicationFee : platformFee;

        if (fees > msg.value) {
            revert CurrencyTransferLib.Error_insufficientValue();
        }

        // pay platform fee
        if (platformFee > 0) {
            CurrencyTransferLib.safeTransferNativeToken(platformFeeRecipient, platformFee);

            emit PaidPlatformFee(address(0), platformFee);
        }

        // pay application fee
        if (applicationFee > 0) {
            if (isNativeToken) {
                CurrencyTransferLib.safeTransferNativeToken(applicationFeeRecipient, applicationFee);
            } else {
                CurrencyTransferLib.safeTransferERC20(_currency, msg.sender, applicationFeeRecipient, applicationFee);
            }

            emit PaidApplicationFee(_currency, applicationFee);
        }

        // send remaining
        // Get recipient from royaltyInfo
        // TODO: is passing the 0 token id and 0 for price best practice here?
        // We are only after a place to send funds. This could be included in the drop?
        (address to,) = IERC2981(_tokenContract).royaltyInfo(0, 0);

        if (isNativeToken) {
            CurrencyTransferLib.safeTransferNativeToken(to, msg.value - fees);
        } else {
            CurrencyTransferLib.safeTransferERC20(_currency, msg.sender, to, totalPrice - applicationFee);
        }
    }
}

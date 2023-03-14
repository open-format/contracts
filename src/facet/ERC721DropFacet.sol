// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721Drop, IERC721Drop} from "src/extensions/ERC721Drop/ERC721Drop.sol";
import {ICompatibleERC721} from "src/extensions/ERC721Drop/ICompatibleERC721.sol";
import {ERC721DropStorage} from "src/extensions/ERC721Drop/ERC721DropStorage.sol";

import {PlatformFee} from "src/extensions/platformFee/PlatformFee.sol";
import {ApplicationFee} from "src/extensions/applicationFee/ApplicationFee.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

contract ERC721DropFacet is ERC721Drop, PlatformFee, ApplicationFee {
    error ERC721DropFacet_EIP2981NotSupported();
    error ERC721DropFacet_royaltyRecipientNotFound();
    /**
     * @dev override before setClaimCondition to add platform fee
     *      requires msg.value to be equal or more than base platform fee
     *      when calling setClaimCondition
     */

    function _beforeSetClaimCondition(address _tokenContract, ERC721DropStorage.ClaimCondition calldata _condition)
        internal
        override
    {
        // token contracts must support the royalty standard
        bool supportsERC281 = ICompatibleERC721(_tokenContract).supportsInterface(0x2a55205a);
        if (!supportsERC281) {
            revert ERC721DropFacet_EIP2981NotSupported();
        }

        (address recipient, uint256 amount) = _platformFeeInfo(0);

        if (amount == 0) {
            return;
        }

        // ensure the ether being sent was included in the transaction
        if (amount > msg.value) {
            revert CurrencyTransferLib.Error_insufficientValue();
        }

        CurrencyTransferLib.safeTransferNativeToken(recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }

    function _transferTokensOnClaim(address _tokenContract, address _to, uint256 _quantityBeingClaimed)
        internal
        override
    {
        if (_quantityBeingClaimed > 1) {
            ICompatibleERC721(_tokenContract).batchMintTo(_to, _quantityBeingClaimed);
        } else {
            ICompatibleERC721(_tokenContract).mintTo(_to);
        }
    }

    function _collectPriceOnClaim(address _tokenContract, uint256 _quantity, address _currency, uint256 _pricePerToken)
        internal
        override
        onlyAcceptedCurrencies(_currency)
    {
        // Get recipient from royaltyInfo
        // We are only after an address to send funds so price and id doesn't matter
        (address royaltyRecipient,) = IERC2981(_tokenContract).royaltyInfo(0, 0);

        if (royaltyRecipient == address(0)) {
            revert ERC721DropFacet_royaltyRecipientNotFound();
        }

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

        // pay nft royalty recipient
        if (isNativeToken) {
            CurrencyTransferLib.safeTransferNativeToken(royaltyRecipient, msg.value - fees);
        } else {
            CurrencyTransferLib.safeTransferERC20(_currency, msg.sender, royaltyRecipient, totalPrice - applicationFee);
        }
    }
}

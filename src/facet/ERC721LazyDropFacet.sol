// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC721LazyDrop, IERC721LazyDrop} from "src/extensions/ERC721LazyDrop/ERC721LazyDrop.sol";
import {ICompatibleERC721} from "src/extensions/ERC721LazyDrop/ICompatibleERC721.sol";
import {ERC721LazyDropStorage} from "src/extensions/ERC721LazyDrop/ERC721LazyDropStorage.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

/**
 * @title   "ERC721LazyDrop Facet"
 * @notice  Allows token contract admins/owners to use an app to drop lazy minted tokens for a price
 */

contract ERC721LazyDropFacet is ERC721LazyDrop {
    error ERC721LazyDropFacet_EIP2981NotSupported();
    error ERC721LazyDropFacet_royaltyRecipientNotFound();

    /**
     * @dev override to handle minting of NFT's
     */

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

    /**
     * @dev override to pay the royalty receiver
     */

    function _collectPriceOnClaim(address _tokenContract, uint256 _quantity, address _currency, uint256 _pricePerToken)
        internal
        override
    {
        // Get recipient from royaltyInfo
        // We are only after an address to send funds so price and id doesn't matter
        (address royaltyRecipient,) = IERC2981(_tokenContract).royaltyInfo(0, 0);

        if (royaltyRecipient == address(0)) {
            revert ERC721LazyDropFacet_royaltyRecipientNotFound();
        }

        uint256 totalPrice = _quantity * _pricePerToken;
        bool isNativeToken = _currency == CurrencyTransferLib.NATIVE_TOKEN;


        // pay nft royalty recipient
        if (isNativeToken) {
            CurrencyTransferLib.safeTransferNativeToken(royaltyRecipient, msg.value);
        } else {
            CurrencyTransferLib.safeTransferERC20(_currency, msg.sender, royaltyRecipient, totalPrice);
        }
    }
}

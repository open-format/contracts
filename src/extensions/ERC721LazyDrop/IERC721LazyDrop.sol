// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ERC721LazyDropStorage} from "./ERC721LazyDropStorage.sol";

interface IERC721LazyDrop {
    error ERC721LazyDrop_notAuthorised();
    error ERC721LazyDrop_maxSupplyClaimed();
    error ERC721LazyDrop_invalidPriceOrCurrency();
    error ERC721LazyDrop_quantityZeroOrExceededWalletLimit();
    error ERC721LazyDrop_exceededMaxSupply();
    error ERC721LazyDrop_cantClaimYet();

    event ClaimConditionUpdated(
        address tokenContract, ERC721LazyDropStorage.ClaimCondition condition, bool resetEligibility
    );
    event ClaimConditionRemoved(address tokenContract);
    event TokensClaimed(address tokenContract, address claimer, address receiver, uint256 quantityClaimed);
}

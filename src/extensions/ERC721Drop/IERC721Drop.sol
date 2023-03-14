// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721DropStorage} from "./ERC721DropStorage.sol";

interface IERC721Drop {
    error ERC721Drop_notAuthorised();
    error ERC721Drop_maxSupplyClaimed();
    error ERC721Drop_invalidPriceOrCurrency();
    error ERC721Drop_quantityZeroOrExceededWalletLimit();
    error ERC721Drop_exceededMaxSupply();
    error ERC721Drop_cantClaimYet();

    event ClaimConditionUpdated(ERC721DropStorage.ClaimCondition condition, bool resetEligibility);
    event TokensClaimed(address tokenContract, address claimer, address receiver, uint256 quantityClaimed);
}

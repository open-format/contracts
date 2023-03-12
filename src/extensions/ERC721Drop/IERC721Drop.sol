// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721DropStorage} from "./ERC721DropStorage.sol";

interface IERC721Drop {
    event ClaimConditionUpdated(ERC721DropStorage.ClaimCondition condition, bool resetEligibility);
    event TokensClaimed(address tokenContract, address claimer, address receiver, uint256 quantityClaimed);
}

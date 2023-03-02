// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

library ERC721DropFacetStorage {
    struct ClaimCondition {
        uint256 startTimestamp;
        uint256 supplyClaimed;
        uint256 maxClaimableSupply;
        uint256 quantityLimitPerWallet;
        uint256 pricePerToken;
        address currency;
    }

    struct Layout {
        // tokenContract => activeClaimCondition
        mapping(address => ClaimCondition) activeClaimConditions;
        // tokenContract => claimConditionId
        mapping(address => bytes32) activeConditionIds;
        // claimConditionId => (wallet => supplyClaimed)
        mapping(bytes32 => mapping(address => uint256)) supplyClaimedByWallet;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ERC721DropFacet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}

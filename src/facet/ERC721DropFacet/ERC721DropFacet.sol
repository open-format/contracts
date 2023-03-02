// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";

import {ERC721DropFacetStorage} from "./ERC721DropFacetStorage.sol";

import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {PlatformFee} from "@extensions/platformFee/PlatformFee.sol";
import {ApplicationFee} from "@extensions/applicationFee/ApplicationFee.sol";

/**
 * @title   "ERC721Drop Facet"
 * @notice  (WIP) Allows nft contract owners to setup a drop on an app
 *          For an nft to contract to be compatible:
 *          erc721 contract must have `owner() returns (address)`, `mintTo(address)` and `batchMintTo(address,uint256)`
 *          and give access to the app to perform those functions
 *
 *          This contract is heavily inspired from thirdwebs SinglePhaseDrop extension.
 *          https://github.com/thirdweb-dev/contracts/blob/main/contracts/extension/DropSinglePhase.sol
 *          Modified to work as a service rather than be included in erc721 contracts
 *          Some logic has been removed but may be added in again (merkle tree, metadata)
 */

interface CompatibleERC721 {
    function owner() external returns (address);
    function mintTo(address) external;
    function batchMintTo(address) external;
}

contract ERC721DropFacet is PlatformFee, ApplicationFee, Ownable {
    // TODO: refactor to IERC721DropFacet
    event ClaimConditionUpdated(ERC721DropFacetStorage.ClaimCondition condition, bool resetEligibility);

    // TODO: add fee payments
    function setClaimCondition(
        address tokenContract,
        ERC721DropFacetStorage.ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external {
        if (!_isTokenContractOwner(tokenContract)) {
            revert("must be contract owner");
        }

        ERC721DropFacetStorage.Layout storage l = ERC721DropFacetStorage.layout();

        bytes32 targetConditionId = l.activeConditionIds[tokenContract];
        uint256 supplyClaimedAlready = l.activeClaimConditions[tokenContract].supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), block.number));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        l.activeClaimConditions[tokenContract] = ERC721DropFacetStorage.ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerWallet: _condition.quantityLimitPerWallet,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency
        });

        l.activeConditionIds[tokenContract] = targetConditionId;

        emit ClaimConditionUpdated(_condition, _resetClaimEligibility);
    }

    function removeClaimCondition(address tokenContract) external {
        if (!_isTokenContractOwner(tokenContract)) {
            revert("must be contract owner");
        }
    }

    function claim(address tokenContract, address receiver, uint256 quantity, address currency, uint256 pricePerToken)
        external
    {}

    // INTERNAL FUNCTIONS
    // TODO: refactor to ERC721DropFacetInternal.sol

    function _isTokenContractOwner(address _tokenContract) internal virtual returns (bool) {
        return CompatibleERC721(_tokenContract).owner() == msg.sender;
    }

    function _dropMsgSender() internal virtual returns (address) {
        return msg.sender;
    }
}

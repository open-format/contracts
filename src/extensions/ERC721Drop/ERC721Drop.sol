// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC721Drop} from "./IERC721Drop.sol";
import {ERC721DropStorage} from "./ERC721DropStorage.sol";
import {ERC721DropInternal} from "./ERC721DropInternal.sol";

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

abstract contract ERC721Drop is IERC721Drop, ERC721DropInternal {
    function getClaimCondition(address _tokenContract)
        external
        view
        returns (ERC721DropStorage.ClaimCondition memory)
    {
        return _getClaimCondition(_tokenContract);
    }

    // TODO: consider renaming to ERC721Drop_claim to avoid facet function clashes, could also make it internal/public
    // TODO: consider making this ERC agnostic ... param currency -> priceCurrency

    function claim(
        address _tokenContract,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) external payable {
        // TODO: _beforeClaim hook

        _verifyClaim(_tokenContract, _dropMsgSender(), _quantity, _currency, _pricePerToken);

        // Update contract state.
        _updateClaimConditionQuantity(_tokenContract, _dropMsgSender(), _quantity);

        // If there's a price, collect price.
        _collectPriceOnClaim(_tokenContract, _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.

        // NOTE: web three's implementation returns startTokenId and adds it to tokenClaimed event
        // have removed for now to limit ERC721 compatibility requirements
        _transferTokensOnClaim(_tokenContract, _receiver, _quantity);

        // TODO: afterClaim hook

        emit TokensClaimed(_tokenContract, _dropMsgSender(), _receiver, _quantity);
    }

    // TODO: add fee payments
    // TODO: consider renaming to ERC721Drop_claim to avoid facet function clashes
    function setClaimCondition(
        address _tokenContract,
        ERC721DropStorage.ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external payable {
        if (!_isTokenContractOwner(_tokenContract)) {
            revert("must be contract owner");
        }

        bytes32 targetConditionId = _getClaimConditionId(_tokenContract);
        uint256 supplyClaimedAlready = _getClaimCondition(_tokenContract).supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), block.number));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        // TODO: _beforeSetClaimCondition hook
        // This will be used to pay fees and add functionally without needing to override logic

        l.claimConditions[_tokenContract] = ERC721DropStorage.ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerWallet: _condition.quantityLimitPerWallet,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency
        });

        l.claimConditionIds[_tokenContract] = targetConditionId;

        emit ClaimConditionUpdated(_condition, _resetClaimEligibility);
    }

    function removeClaimCondition(address tokenContract) external {
        // TODO: possibly only address that created the claim?
        if (!_isTokenContractOwner(tokenContract)) {
            revert("must be contract owner");
        }

        // TODO: remove claim condition from storage

        // TODO: emit event
    }
}

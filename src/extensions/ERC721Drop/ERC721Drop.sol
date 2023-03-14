// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

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

abstract contract ERC721Drop is IERC721Drop, ERC721DropInternal, ReentrancyGuard {
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
    ) external payable nonReentrant {
        _verifyClaim(_tokenContract, _dropMsgSender(), _quantity, _currency, _pricePerToken);

        // Update contract state.
        _updateClaimConditionQuantity(_tokenContract, _dropMsgSender(), _quantity);

        // If there's a price, collect price.
        _collectPriceOnClaim(_tokenContract, _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.
        // NOTE: web three's implementation returns startTokenId and adds it to tokenClaimed event
        // have removed for now to limit ERC721 compatibility requirements
        _transferTokensOnClaim(_tokenContract, _receiver, _quantity);

        emit TokensClaimed(_tokenContract, _dropMsgSender(), _receiver, _quantity);
    }

    // TODO: consider renaming to ERC721Drop_claim to avoid facet function clashes
    function setClaimCondition(
        address _tokenContract,
        ERC721DropStorage.ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external payable nonReentrant {
        if (!_isTokenContractOwner(_tokenContract)) {
            revert("must be contract owner");
        }

        // perform any extra checks
        _beforeSetClaimCondition(_tokenContract, _condition);

        bytes32 targetConditionId = _getClaimConditionId(_tokenContract);
        uint256 supplyClaimedAlready = _getClaimCondition(_tokenContract).supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            // create new claimConditionId to reset supply claimed by wallets
            // abi.encode vs abi.encodePacked is used to mitigate collisions
            targetConditionId = keccak256(abi.encode(_tokenContract, block.number));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        _setClaimCondition(
            _tokenContract,
            ERC721DropStorage.ClaimCondition({
                startTimestamp: _condition.startTimestamp,
                maxClaimableSupply: _condition.maxClaimableSupply,
                supplyClaimed: supplyClaimedAlready,
                quantityLimitPerWallet: _condition.quantityLimitPerWallet,
                pricePerToken: _condition.pricePerToken,
                currency: _condition.currency
            })
        );

        _setClaimConditionId(_tokenContract, targetConditionId);

        // perform any extra logic
        _afterSetClaimCondition(_tokenContract, _condition);

        emit ClaimConditionUpdated(_condition, _resetClaimEligibility);
    }

    function removeClaimCondition(address tokenContract) external {
        // TODO: possibly only address that created the claim?
        if (!_isTokenContractOwner(tokenContract)) {
            revert("must be contract owner");
        }

        // TODO: remove claim condition from storage?
    }
}

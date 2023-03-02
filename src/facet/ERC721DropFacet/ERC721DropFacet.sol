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
    function mintTo(address _to) external;
    function batchMintTo(address _to, uint256 _quantity) external;

    // if `owner()` is not implemented checks for DEFAULT_ADMIN_ROLE from access control `hasRole(0x00, msg.sender);`
    function hasRole(bytes32 role, address account) external returns (bool);
}

contract ERC721DropFacet is PlatformFee, ApplicationFee, Ownable {
    // TODO: refactor to IERC721DropFacet
    event ClaimConditionUpdated(ERC721DropFacetStorage.ClaimCondition condition, bool resetEligibility);
    event TokensClaimed(address tokenContract, address claimer, address receiver, uint256 quantityClaimed);

    function claim(
        address _tokenContract,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) external {
        ERC721DropFacetStorage.Layout storage l = ERC721DropFacetStorage.layout();
        bytes32 activeConditionId = l.activeConditionIds[_tokenContract];

        _verifyClaim(_tokenContract, _dropMsgSender(), _quantity, _currency, _pricePerToken);

        // Update contract state.
        l.activeClaimConditions[_tokenContract].supplyClaimed += _quantity;
        l.supplyClaimedByWallet[activeConditionId][_dropMsgSender()] += _quantity;

        // If there's a price, collect price.
        _collectPriceOnClaim(_tokenContract, _quantity, _currency, _pricePerToken);

        // Mint the relevant NFTs to claimer.

        // NOTE: web three's implementation returns startTokenId and adds it to tokenClaimed event
        // have removed for now to limit ERC721 compatibility requirements
        _transferTokensOnClaim(_tokenContract, _receiver, _quantity);

        emit TokensClaimed(_tokenContract, _dropMsgSender(), _receiver, _quantity);
    }

    // TODO: add fee payments
    function setClaimCondition(
        address _tokenContract,
        ERC721DropFacetStorage.ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external {
        if (!_isTokenContractOwner(_tokenContract)) {
            revert("must be contract owner");
        }

        ERC721DropFacetStorage.Layout storage l = ERC721DropFacetStorage.layout();

        bytes32 targetConditionId = l.activeConditionIds[_tokenContract];
        uint256 supplyClaimedAlready = l.activeClaimConditions[_tokenContract].supplyClaimed;

        if (_resetClaimEligibility) {
            supplyClaimedAlready = 0;
            targetConditionId = keccak256(abi.encodePacked(_dropMsgSender(), block.number));
        }

        if (supplyClaimedAlready > _condition.maxClaimableSupply) {
            revert("max supply claimed");
        }

        l.activeClaimConditions[_tokenContract] = ERC721DropFacetStorage.ClaimCondition({
            startTimestamp: _condition.startTimestamp,
            maxClaimableSupply: _condition.maxClaimableSupply,
            supplyClaimed: supplyClaimedAlready,
            quantityLimitPerWallet: _condition.quantityLimitPerWallet,
            pricePerToken: _condition.pricePerToken,
            currency: _condition.currency
        });

        l.activeConditionIds[_tokenContract] = targetConditionId;

        emit ClaimConditionUpdated(_condition, _resetClaimEligibility);
    }

    function removeClaimCondition(address tokenContract) external {
        if (!_isTokenContractOwner(tokenContract)) {
            revert("must be contract owner");
        }
    }

    // INTERNAL FUNCTIONS
    // TODO: refactor to ERC721DropFacetInternal.sol

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function _verifyClaim(
        address _tokenContract,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) internal view {
        ERC721DropFacetStorage.Layout storage l = ERC721DropFacetStorage.layout();

        ERC721DropFacetStorage.ClaimCondition memory currentClaimPhase = l.activeClaimConditions[_tokenContract];
        bytes32 activeConditionId = l.activeConditionIds[_tokenContract];

        uint256 claimLimit = currentClaimPhase.quantityLimitPerWallet;
        uint256 claimPrice = currentClaimPhase.pricePerToken;
        address claimCurrency = currentClaimPhase.currency;

        uint256 _supplyClaimedByWallet = l.supplyClaimedByWallet[activeConditionId][_claimer];

        if (_currency != claimCurrency || _pricePerToken != claimPrice) {
            revert("!PriceOrCurrency");
        }

        if (_quantity == 0 || (_quantity + _supplyClaimedByWallet > claimLimit)) {
            revert("!Qty");
        }

        if (currentClaimPhase.supplyClaimed + _quantity > currentClaimPhase.maxClaimableSupply) {
            revert("!MaxSupply");
        }

        if (currentClaimPhase.startTimestamp > block.timestamp) {
            revert("cant claim yet");
        }
    }

    function _collectPriceOnClaim(
        address _tokenContract,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual {
        // TODO: add fee payments
        // TODO: add payments - possibly use royalty interface?
    }

    /// @dev Transfers the NFTs being claimed.
    function _transferTokensOnClaim(address _tokenContract, address _to, uint256 _quantityBeingClaimed)
        internal
        virtual
    {
        // TODO: mintTo
        if (_quantityBeingClaimed > 1) {
            CompatibleERC721(_tokenContract).batchMintTo(_to, _quantityBeingClaimed);
        } else {
            CompatibleERC721(_tokenContract).mintTo(_to);
        }
    }

    function _isTokenContractOwner(address _tokenContract) internal virtual returns (bool) {
        try CompatibleERC721(_tokenContract).owner() returns (address _owner) {
            return _owner == msg.sender;
        } catch {
            // owner not implemented, try access control DEFAULT_ADMIN_ROLE
            return CompatibleERC721(_tokenContract).hasRole(0x00, msg.sender);
        }
    }

    function _dropMsgSender() internal virtual returns (address) {
        return msg.sender;
    }
}

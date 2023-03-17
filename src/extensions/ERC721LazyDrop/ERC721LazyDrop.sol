// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

import {IERC721LazyDrop} from "./IERC721LazyDrop.sol";
import {ERC721LazyDropStorage} from "./ERC721LazyDropStorage.sol";
import {ERC721LazyDropInternal} from "./ERC721LazyDropInternal.sol";

/**
 * @title   "ERC721LazyDrop extension"
 * @notice  (WIP) Allows nft contract owners to setup a drop on an app
 *          See ICompatibleERC721.sol for necessary interface.
 *          The inheriting contract must be given minter access to perform the mintTo and batchMintTo functions
 *
 *          This contract is heavily inspired from thirdwebs SinglePhaseDrop extension.
 *          https://github.com/thirdweb-dev/contracts/blob/main/contracts/extension/DropSinglePhase.sol
 *          Modified to work as a service rather than be included in erc721 contracts
 *          Some logic has been removed but may be added in again (merkle tree, metadata)
 */

abstract contract ERC721LazyDrop is IERC721LazyDrop, ERC721LazyDropInternal, ReentrancyGuard {
    /**
     * @notice gets the current claim condition for a given token contract
     * @param _tokenContract the address of the token contract
     * @return ERC721LazyDropStorage.ClaimCondition the claim condition for the give token contract,
     *         will be all zeros if no claim condition exists
     */
    function ERC721LazyDrop_getClaimCondition(address _tokenContract)
        external
        view
        returns (ERC721LazyDropStorage.ClaimCondition memory)
    {
        return _getClaimCondition(_tokenContract);
    }

    /**
     * @notice verifies a claim against the current claim condition for a given token contract
     * @dev will return true for a valid claim and revert if is invalid
     * @param _tokenContract the address of the token contract
     * @param _claimer the address making the claim
     * @param _quantity the amount of the tokens claiming
     * @param _currency the currency of the claim
     * @param _pricePerToken the price per token of the claim
     * @return bool whether the claim is valid
     */
    function ERC721LazyDrop_verifyClaim(
        address _tokenContract,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) external view returns (bool) {
        _verifyClaim(_tokenContract, _claimer, _quantity, _currency, _pricePerToken);
        return true;
    }

    /**
     * @notice claims given quantity of tokens for a price
     * @dev inheriting contracts should override `_collectPriceOnClaim` to handle payments
     *      and `_transferTokensOnClaim` to handle the transfer of tokens.
     *      emits TokensClaimed event on successful claim
     *      This function is nonReentrant as it depends on external calls to given token contract
     *
     * @param _tokenContract the address of the token contract
     * @param _receiver the address to send the claimed tokens
     * @param _quantity the amount of the tokens claiming
     * @param _currency the currency of the claim
     * @param _pricePerToken the price per token of the claim
     */
    function ERC721LazyDrop_claim(
        address _tokenContract,
        address _receiver,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) external payable nonReentrant {
        _verifyClaim(_tokenContract, _dropMsgSender(), _quantity, _currency, _pricePerToken);

        _updateClaimConditionQuantity(_tokenContract, _dropMsgSender(), _quantity);

        _collectPriceOnClaim(_tokenContract, _quantity, _currency, _pricePerToken);

        _transferTokensOnClaim(_tokenContract, _receiver, _quantity);

        emit TokensClaimed(_tokenContract, _dropMsgSender(), _receiver, _quantity);
    }

    /**
     * @notice sets the claim condition for a given token contract.
     * @dev    inheriting contracts can override `_beforeSetClaimCondition` and `_afterSetClaimCondition` to perform
     *         extra checks and logic. `_canSetClaimCondition` can be overridden to give different access.
     *         emits ClaimedConditionUpdated event on successfully setting a claim.
     *         Is non-reentrant as it depends on external calls to the given token contract
     * @param _tokenContract the address of the token contract
     * @param _condition the claim condition to set, see `ERC721LazyDropStorage.ClaimCondition`
     * @param _resetClaimEligibility resets total supply claimed and the claimed tokens per wallet
     */
    function ERC721LazyDrop_setClaimCondition(
        address _tokenContract,
        ERC721LazyDropStorage.ClaimCondition calldata _condition,
        bool _resetClaimEligibility
    ) external payable nonReentrant {
        if (!_canSetClaimCondition(_tokenContract)) {
            revert ERC721LazyDrop_notAuthorised();
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
            revert ERC721LazyDrop_maxSupplyClaimed();
        }

        _setClaimCondition(
            _tokenContract,
            ERC721LazyDropStorage.ClaimCondition({
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

        emit ClaimConditionUpdated(_tokenContract, _condition, _resetClaimEligibility);
    }

    /**
     * @notice removes a claim condition for a given token contract
     * @dev    this is more gas efficient than setting the claim condition params to zero
     *         emits ClaimConditionRemoved event
     * @param _tokenContract the address of the token contract to remove claim condition
     */
    function ERC721LazyDrop_removeClaimCondition(address _tokenContract) external {
        if (!_canSetClaimCondition(_tokenContract)) {
            revert ERC721LazyDrop_notAuthorised();
        }

        _removeClaimCondition(_tokenContract);

        emit ClaimConditionRemoved(_tokenContract);
    }
}

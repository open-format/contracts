// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC721Drop} from "./IERC721Drop.sol";
import {ERC721DropStorage} from "./ERC721DropStorage.sol";
import {ICompatibleERC721} from "./ICompatibleERC721.sol";

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

abstract contract ERC721DropInternal is IERC721Drop {
    function _getClaimCondition(address _tokenContract)
        internal
        view
        returns (ERC721DropStorage.ClaimCondition storage)
    {
        return ERC721DropStorage.layout().claimConditions[_tokenContract];
    }

    function _setClaimCondition(address _tokenContract, ERC721DropStorage.ClaimCondition memory _claimCondition)
        internal
    {
        ERC721DropStorage.layout().claimConditions[_tokenContract] = _claimCondition;
    }

    function _getClaimConditionId(address _tokenContract) internal view returns (bytes32) {
        return ERC721DropStorage.layout().claimConditionIds[_tokenContract];
    }

    function _setClaimConditionId(address _tokenContract, bytes32 _id) internal {
        ERC721DropStorage.layout().claimConditionIds[_tokenContract] = _id;
    }

    function _getSupplyClaimedByWallet(address _tokenContract, address _claimer) internal view returns (uint256) {
        ERC721DropStorage.Layout storage l = ERC721DropStorage.layout();
        bytes32 activeConditionId = l.claimConditionIds[_tokenContract];
        return l.supplyClaimedByWallet[activeConditionId][_claimer];
    }

    function _updateClaimConditionQuantity(address _tokenContract, address _wallet, uint256 _quantity)
        internal
        virtual
    {
        ERC721DropStorage.Layout storage l = ERC721DropStorage.layout();

        bytes32 claimConditionId = l.claimConditionIds[_tokenContract];
        l.claimConditions[_tokenContract].supplyClaimed += _quantity;
        l.supplyClaimedByWallet[claimConditionId][_wallet] += _quantity;
    }

    /// @dev Checks a request to claim NFTs against the active claim condition's criteria.
    function _verifyClaim(
        address _tokenContract,
        address _claimer,
        uint256 _quantity,
        address _currency,
        uint256 _pricePerToken
    ) internal view virtual {
        ERC721DropStorage.ClaimCondition memory claimCondition = _getClaimCondition(_tokenContract);
        uint256 supplyClaimedByWallet = _getSupplyClaimedByWallet(_tokenContract, _claimer);

        if (_currency != claimCondition.currency || _pricePerToken != claimCondition.pricePerToken) {
            revert ERC721Drop_invalidPriceOrCurrency();
        }

        if (_quantity == 0 || (_quantity + supplyClaimedByWallet > claimCondition.quantityLimitPerWallet)) {
            revert ERC721Drop_quantityZeroOrExceededWalletLimit();
        }

        if (claimCondition.supplyClaimed + _quantity > claimCondition.maxClaimableSupply) {
            revert ERC721Drop_exceededMaxSupply();
        }

        if (claimCondition.startTimestamp > block.timestamp) {
            revert ERC721Drop_cantClaimYet();
        }
    }

    /// @dev inheriting contract must override this function to handle payments
    function _collectPriceOnClaim(
        address _tokenContract,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual;

    /// @dev inheriting contract must override this function to handle transfer of tokens
    function _transferTokensOnClaim(address _tokenContract, address _to, uint256 _quantityBeingClaimed)
        internal
        virtual;

    function _canSetClaimCondition(address _tokenContract) internal virtual returns (bool) {
        try ICompatibleERC721(_tokenContract).owner() returns (address _owner) {
            return _owner == msg.sender;
        } catch {
            // owner not implemented, try access control DEFAULT_ADMIN_ROLE
            return ICompatibleERC721(_tokenContract).hasRole(0x00, msg.sender);
        }
    }

    function _dropMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    function _beforeSetClaimCondition(address _tokenContract, ERC721DropStorage.ClaimCondition calldata _condition)
        internal
        virtual
    {}

    function _afterSetClaimCondition(address _tokenContract, ERC721DropStorage.ClaimCondition calldata _condition)
        internal
        virtual
    {}
}

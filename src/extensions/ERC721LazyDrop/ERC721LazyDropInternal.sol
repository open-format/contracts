// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IERC721LazyDrop} from "./IERC721LazyDrop.sol";
import {ERC721LazyDropStorage} from "./ERC721LazyDropStorage.sol";
import {ICompatibleERC721} from "./ICompatibleERC721.sol";

abstract contract ERC721LazyDropInternal is IERC721LazyDrop {
    function _getClaimCondition(address _tokenContract)
        internal
        view
        returns (ERC721LazyDropStorage.ClaimCondition storage)
    {
        return ERC721LazyDropStorage.layout().claimConditions[_tokenContract];
    }

    function _setClaimCondition(address _tokenContract, ERC721LazyDropStorage.ClaimCondition memory _claimCondition)
        internal
    {
        ERC721LazyDropStorage.layout().claimConditions[_tokenContract] = _claimCondition;
    }

    function _removeClaimCondition(address _tokenContract) internal {
        delete ERC721LazyDropStorage.layout().claimConditions[_tokenContract];
    }

    function _getClaimConditionId(address _tokenContract) internal view returns (bytes32) {
        return ERC721LazyDropStorage.layout().claimConditionIds[_tokenContract];
    }

    function _setClaimConditionId(address _tokenContract, bytes32 _id) internal {
        ERC721LazyDropStorage.layout().claimConditionIds[_tokenContract] = _id;
    }

    function _getSupplyClaimedByWallet(address _tokenContract, address _claimer) internal view returns (uint256) {
        ERC721LazyDropStorage.Layout storage l = ERC721LazyDropStorage.layout();
        bytes32 activeConditionId = l.claimConditionIds[_tokenContract];
        return l.supplyClaimedByWallet[activeConditionId][_claimer];
    }

    function _updateClaimConditionQuantity(address _tokenContract, address _wallet, uint256 _quantity)
        internal
        virtual
    {
        ERC721LazyDropStorage.Layout storage l = ERC721LazyDropStorage.layout();

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
        ERC721LazyDropStorage.ClaimCondition memory claimCondition = _getClaimCondition(_tokenContract);
        uint256 supplyClaimedByWallet = _getSupplyClaimedByWallet(_tokenContract, _claimer);

        if (_currency != claimCondition.currency || _pricePerToken != claimCondition.pricePerToken) {
            revert ERC721LazyDrop_invalidPriceOrCurrency();
        }

        if (_quantity == 0 || (_quantity + supplyClaimedByWallet > claimCondition.quantityLimitPerWallet)) {
            revert ERC721LazyDrop_quantityZeroOrExceededWalletLimit();
        }

        if (claimCondition.supplyClaimed + _quantity > claimCondition.maxClaimableSupply) {
            revert ERC721LazyDrop_exceededMaxSupply();
        }

        if (claimCondition.startTimestamp > block.timestamp) {
            revert ERC721LazyDrop_cantClaimYet();
        }
    }

    /**
     * @dev inheriting contract must override this function to handle payments
     */
    function _collectPriceOnClaim(
        address _tokenContract,
        uint256 _quantityToClaim,
        address _currency,
        uint256 _pricePerToken
    ) internal virtual;

    /**
     * @dev inheriting contract must override this function to handle payments
     */
    function _transferTokensOnClaim(address _tokenContract, address _to, uint256 _quantityBeingClaimed)
        internal
        virtual;

    /**
     * @dev checks if the msg.sender is the owner or admin of the given token contract.
     *      This supports the openzepplin/solidstate `ownable` and `access control` contract defaults.
     *      override to support different access requirements
     */
    function _canSetClaimCondition(address _tokenContract) internal virtual returns (bool) {
        try ICompatibleERC721(_tokenContract).owner() returns (address _owner) {
            return _owner == _dropMsgSender();
        } catch {
            // owner not implemented, try access control DEFAULT_ADMIN_ROLE
            return ICompatibleERC721(_tokenContract).hasRole(0x00, _dropMsgSender());
        }
    }

    function _dropMsgSender() internal virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev inheriting contract can override this function to perform logic before a claim condition is set
     */
    function _beforeSetClaimCondition(address _tokenContract, ERC721LazyDropStorage.ClaimCondition calldata _condition)
        internal
        virtual
    {}

    /**
     * @dev inheriting contract can override this function to perform logic after a claim condition is set
     */
    function _afterSetClaimCondition(address _tokenContract, ERC721LazyDropStorage.ClaimCondition calldata _condition)
        internal
        virtual
    {}
}

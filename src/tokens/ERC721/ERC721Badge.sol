// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC721LazyMint, ADMIN_ROLE} from "./ERC721LazyMint.sol";

contract ERC721Badge is ERC721LazyMint {
    /**
     * @dev this contract is meant to be an implementation for a factory contract
     *      calling initialize in constructor prevents the implementation from being used by third party
     * @param _isTest used to prevent the initialisation. Set to true in unit tests and false in production
     */
    constructor(bool _isTest) ERC721LazyMint(true) {
        if (!_isTest) {
            initialize(address(0), "", "", address(0), 0, "");
        }
    }

    /**
     * @notice Lets an authorized address set base uri for a batch of lazy minted tokens.
     * @param _tokenId a tokenId that is contained in the desired batch
     * @param _baseURIForTokens the base URI to be set
     *
     * @dev when the first batch is lazy minted with a MAX_INT (2 ** 256 - 1) amount the baseURI will be set for all tokens
     */
    function setBaseURI(uint256 _tokenId, string calldata _baseURIForTokens) public payable nonReentrant {
        if (!_canSetBaseURI()) {
            revert ERC721LazyMint.ERC721LazyMint_notAuthorized();
        }

        (address platformFeeRecipient, uint256 platformFeeAmount) = _checkPlatformFee();

        (uint256 batchId,) = _getBatchId(_tokenId);
        _setBaseURI(batchId, _baseURIForTokens);

        _payPlatformFee(platformFeeRecipient, platformFeeAmount);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetBaseURI() internal view virtual returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender);
    }
}

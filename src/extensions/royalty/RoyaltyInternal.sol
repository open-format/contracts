// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IRoyalty} from "./IRoyalty.sol";
import {RoyaltyStorage} from "./RoyaltyStorage.sol";

abstract contract RoyaltyInternal is IRoyalty {
    /// @dev Lets a contract admin update the default royalty recipient and bps.
    function _setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) internal virtual {
        if (_royaltyBps > 10_000) {
            revert Royalty_exceedsMaxBPS();
        }
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();
        l.royaltyRecipient = _royaltyRecipient;
        l.royaltyBps = uint16(_royaltyBps);

        emit DefaultRoyalty(_royaltyRecipient, _royaltyBps);
    }

    function _getDefaultRoyaltyInfo() internal view virtual returns (address, uint16) {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();
        return (l.royaltyRecipient, uint16(l.royaltyBps));
    }

    /// @dev Lets a contract admin set the royalty recipient and bps for a particular token Id.
    function _setRoyaltyInfoForToken(uint256 _tokenId, address _recipient, uint256 _bps) internal {
        if (_bps > 10_000) {
            revert Royalty_exceedsMaxBPS();
        }

        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();
        l.royaltyInfoForToken[_tokenId] = RoyaltyStorage.RoyaltyInfo({recipient: _recipient, bps: uint16(_bps)});

        emit RoyaltyForToken(_tokenId, _recipient, _bps);
    }

    function _getRoyaltyInfoForToken(uint256 _tokenId) internal view virtual returns (address, uint16) {
        RoyaltyStorage.Layout storage l = RoyaltyStorage.layout();
        RoyaltyStorage.RoyaltyInfo memory royaltyForToken = l.royaltyInfoForToken[_tokenId];

        return royaltyForToken.recipient == address(0)
            ? (l.royaltyRecipient, l.royaltyBps)
            : (royaltyForToken.recipient, royaltyForToken.bps);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual returns (bool);
}

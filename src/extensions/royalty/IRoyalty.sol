// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

/**
 *  Thirdweb's `Royalty` is a contract extension to be used with any base contract. It exposes functions for setting and reading
 *  the recipient of royalty fee and the royalty fee basis points, and lets the inheriting contract perform conditional logic
 *  that uses information about royalty fees, if desired.
 *
 *  The `Royalty` contract is ERC2981 compliant.
 */

interface IRoyalty is IERC2981 {
    error Royalty_exceedsMaxBPS();
    error Royalty_notAuthorized();

    /// @dev Emitted when royalty info is updated.
    event DefaultRoyalty(address indexed newRoyaltyRecipient, uint256 newRoyaltyBps);

    /// @dev Emitted when royalty recipient for tokenId is set
    event RoyaltyForToken(uint256 indexed tokenId, address indexed royaltyRecipient, uint256 royaltyBps);

    /// @dev Returns the royalty recipient and fee bps.
    function getDefaultRoyaltyInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the royalty bps and recipient.
    function setDefaultRoyaltyInfo(address _royaltyRecipient, uint256 _royaltyBps) external;

    /// @dev Lets a module admin set the royalty recipient for a particular token Id.
    function setRoyaltyInfoForToken(uint256 tokenId, address recipient, uint256 bps) external;

    /// @dev Returns the royalty recipient for a particular token Id.
    function getRoyaltyInfoForToken(uint256 tokenId) external view returns (address, uint16);
}

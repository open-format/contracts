// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationFee} from "../extensions/applicationFee/ApplicationFee.sol";
import {ApplicationAccess, IApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";

interface NFT {
    function mintTo(address to, string memory tokenURI) external;
    function batchMintTo(address to, uint256 quantity, string memory baseURI) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

interface Token {
    function mintTo(address to, uint256 amount) external;
    function transferFrom(address holder, address receipient, uint256 amount) external;
    function hasRole(bytes32 role, address account) external returns (bool);
    function allowance(address holder, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

contract RewardsFacet is Multicall, SafeOwnable {
    event TokenMinted(address token, address to, uint256 amount, bytes32 id, bytes32 activityType, string uri);
    event TokenTransferred(address token, address to, uint256 amount, bytes32 id, bytes32 activityType, string uri);
    event BadgeMinted(address token, uint256 quantity, address to, bytes32 id, bytes32 activityType, string uri);
    event BadgeTransferred(address token, address to, uint256 tokenId, bytes32 id, bytes32 activityType, string uri);

    error RewardsFacet_NotAuthorized();
    error RewardsFacet_InsufficientBalance();

    function mintERC20(
        address _token,
        address _to,
        uint256 _amount,
        bytes32 _id,
        bytes32 _activityType,
        string calldata _uri
    ) public {
        if (!_canMint(_token)) {
            revert RewardsFacet_NotAuthorized();
        }

        Token(_token).mintTo(_to, _amount);
        emit TokenMinted(_token, _to, _amount, _id, _activityType, _uri);
    }

    function transferERC20(
        address _token,
        address _to,
        uint256 _amount,
        bytes32 _id,
        bytes32 _activityType,
        string calldata _uri
    ) public {
        Token(_token).transferFrom(msg.sender, _to, _amount);
        emit TokenTransferred(_token, _to, _amount, _id, _activityType, _uri);
    }

    function mintERC721(
        address _token,
        address _to,
        uint256 _quantity,
        string calldata _baseURI,
        bytes32 _id,
        bytes32 _activityType,
        string calldata _uri
    ) public {
        if (!_canMint(_token)) {
            revert RewardsFacet_NotAuthorized();
        }

        NFT(_token).batchMintTo(_to, _quantity, _baseURI);
        emit BadgeMinted(_token, _quantity, _to, _id, _activityType, _uri);
    }

    function transferERC721(
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32 _id,
        bytes32 _activityType,
        string calldata _uri
    ) public {
        NFT(_token).transferFrom(msg.sender, _to, _tokenId);
        emit BadgeTransferred(_token, _to, _tokenId, _id, _activityType, _uri);
    }

    function _canMint(address _token) internal virtual returns (bool) {
        return Token(_token).hasRole(ADMIN_ROLE, msg.sender) || Token(_token).hasRole(MINTER_ROLE, msg.sender);
    }
}

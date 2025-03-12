// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationFee} from "../extensions/applicationFee/ApplicationFee.sol";
import {ApplicationAccess, IApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {IVersionable} from "../extensions/versionable/IVersionable.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {AccessControlInternal} from "@solidstate/contracts/access/access_control/AccessControl.sol";

interface NFT {
    function mintTo(address to, string memory tokenURI) external;
    function batchMintTo(address to, uint256 quantity, string memory baseURI) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns (address);
}

interface Badge {
    function mintTo(address to) external;
    function batchMintTo(address to, uint256 quantity) external;
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
bytes32 constant OPERATOR_ROLE = bytes32(uint256(1));

string constant FACET_VERSION = "1.1.0";
string constant FACET_NAME = "RewardsFacet";

contract RewardsFacet is Multicall, SafeOwnable, AccessControlInternal, IVersionable {
    event TokenMinted(address token, address to, uint256 amount, bytes32 id, bytes32 activityType, string uri);
    event TokenTransferred(address token, address to, uint256 amount, bytes32 id, bytes32 activityType, string uri);
    event ERC721Minted(address token, uint256 quantity, address to, bytes32 id, bytes32 activityType, string uri);
    event BadgeMinted(
        address token, uint256 quantity, address to, bytes32 activityId, bytes32 activityType, bytes data
    );
    event BadgeTransferred(address token, address to, uint256 tokenId, bytes32 id, bytes32 activityType, string uri);

    error RewardsFacet_NotAuthorized();
    error RewardsFacet_InsufficientBalance();

    /**
     * @dev Override to return facet version.
     * @return version This facet version.
     */
    function facetVersion() external pure override returns (string memory) {
        return FACET_VERSION;
    }

    /**
     * @dev Override to return facet name.
     * @return name This facet name.
     */
    function facetName() external pure override returns (string memory) {
        return FACET_NAME;
    }

    function mintERC20(
        address _token,
        address _to,
        uint256 _amount,
        bytes32 _id,
        bytes32 _activityType,
        string calldata _uri
    ) public {
        if (!_isOperator()) {
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
        if (!_isOperator()) {
            revert RewardsFacet_NotAuthorized();
        }

        Token(_token).transferFrom(msg.sender, _to, _amount);
        emit TokenTransferred(_token, _to, _amount, _id, _activityType, _uri);
    }

    /**
     * @notice  Mints a number of badges to an address and broadcasts activity metadata
     * @dev     The sender must have a role of admin or minter on the badge contract.
     *          The app being called must have a minter role on the badge contract.
     *          The activity metadata is emitted as an event for indexing.
     * @param _badgeContract The address of the ERC721 contract that represents all badges of the same type
     * @param _to The address of the recipient of the badges
     * @param _quantity The amount of badges to mint
     * @param _activityId The id associated with this activity for example "beat the boss" or "collected 100 berries"
     * @param _activityType The type of activity e.g "mission" or "action"
     * @param _data Any other data that will be useful
     */
    function batchMintBadge(
        address _badgeContract,
        address _to,
        uint256 _quantity,
        bytes32 _activityId,
        bytes32 _activityType,
        bytes calldata _data
    ) public {
        if (!_isOperator()) {
            revert RewardsFacet_NotAuthorized();
        }

        Badge(_badgeContract).batchMintTo(_to, _quantity);
        emit BadgeMinted(_badgeContract, _quantity, _to, _activityId, _activityType, _data);
    }

    /**
     * @notice  Mints one badge to an address and broadcasts activity metadata.
     * @dev     The sender must have a role of admin or minter on the badge contract.
     *          The app being called must have a minter role on the badge contract.
     *          The activity metadata is emitted as an event for indexing.
     * @param _badgeContract The address of the ERC721 contract that represents all badges of the same type
     * @param _to The address of the recipient of the badge
     * @param _activityId The id associated with this activity for example "beat the boss" or "collected 100 berries"
     * @param _activityType The type of activity for example "mission" or "action"
     * @param _data Any other data that will be useful
     */
    function mintBadge(
        address _badgeContract,
        address _to,
        bytes32 _activityId,
        bytes32 _activityType,
        bytes calldata _data
    ) public {
        if (!_isOperator()) {
            revert RewardsFacet_NotAuthorized();
        }

        Badge(_badgeContract).mintTo(_to);
        emit BadgeMinted(_badgeContract, 1, _to, _activityId, _activityType, _data);
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
        if (!_isOperator()) {
            revert RewardsFacet_NotAuthorized();
        }

        NFT(_token).batchMintTo(_to, _quantity, _baseURI);
        emit ERC721Minted(_token, _quantity, _to, _id, _activityType, _uri);
    }

    function transferERC721(
        address _token,
        address _to,
        uint256 _tokenId,
        bytes32 _id,
        bytes32 _activityType,
        string calldata _uri
    ) public {
        if (!_isOperator()) {
            revert RewardsFacet_NotAuthorized();
        }

        NFT(_token).transferFrom(msg.sender, _to, _tokenId);
        emit BadgeTransferred(_token, _to, _tokenId, _id, _activityType, _uri);
    }

    function _isOperator() internal virtual returns (bool) {
        if (msg.sender == _owner()){
            return true;
        }
        if (_hasRole(ADMIN_ROLE, msg.sender)){
            return true;
        }
        if (_hasRole(OPERATOR_ROLE, msg.sender)){
            return true;
        }

        return false;
    }
}

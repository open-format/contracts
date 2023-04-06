// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationFee} from "../extensions/applicationFee/ApplicationFee.sol";
import {ApplicationAccess, IApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

interface NFT {
    function mintTo(address to, string memory tokenURI) external;
}

interface Token {
    function mintTo(address to, uint256 amount) external;
    function transferFrom(address holder, address receipient, uint256 amount) external;
}

contract RewardsFacet is Multicall, SafeOwnable {
    event Reward(address token, address recipient, uint256 amount, string id, address appId, string activityType);

    function mintERC20(
        address _token,
        address _recipient,
        uint256 _amount,
        string memory _id,
        address _appId,
        string memory _activityType
    ) public {
        Token(_token).mintTo(_recipient, _amount);
        emit Reward(_token, _recipient, _amount, _id, _appId, _activityType);
    }

    function transferERC20(
        address _holder,
        address _token,
        address _recipient,
        uint256 _amount,
        string memory _id,
        address _appId,
        string memory _activityType
    ) public {
        Token(_token).transferFrom(_holder, _recipient, _amount);
        emit Reward(_token, _recipient, _amount, _id, _appId, _activityType);
    }

    function mintERC721(
        address _token,
        address _recipient,
        string memory _tokenURI,
        string memory _id,
        address _appId,
        string memory _activityType
    ) public {
        NFT(_token).mintTo(_recipient, _tokenURI);
        emit Reward(_token, _recipient, 1, _id, _appId, _activityType);
    }
}

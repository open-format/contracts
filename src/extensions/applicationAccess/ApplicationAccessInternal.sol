// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ApplicationAccessStorage} from "./ApplicationAccessStorage.sol";

abstract contract ApplicationAccessInternal is OwnableInternal {
    /**
     * @dev checks if user can create new contracts
     *      zero address approved (open to all) or
     *      _user address approved (whitelisted) or
     *      _user is the app owner
     */
    function _hasCreatorAccess(address _user) internal view returns (bool) {
        ApplicationAccessStorage.Layout storage l = ApplicationAccessStorage.layout();

        return (l.approvedCreators[address(0)] || l.approvedCreators[_user] || _user == _owner());
    }
}

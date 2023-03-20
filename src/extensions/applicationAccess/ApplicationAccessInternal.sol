// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {IApplicationAccess} from "./IApplicationAccess.sol";
import {ApplicationAccessStorage} from "./ApplicationAccessStorage.sol";

abstract contract ApplicationAccessInternal is IApplicationAccess, OwnableInternal {
    /**
     * @dev checks if account can create new contracts
     *      zero address approved (open to all) or
     *      _account address approved (whitelisted) or
     *      _account is the app owner
     * @param _account wallet or contract address to check for creator approval
     */
    function _hasCreatorAccess(address _account) internal view returns (bool) {
        ApplicationAccessStorage.Layout storage l = ApplicationAccessStorage.layout();

        return (l.approvedCreators[address(0)] || l.approvedCreators[_account] || _account == _owner());
    }

    /**
     * @dev sets an array of accounts and their approvals, approve the zero address to open creating to all
     *      will revert if accounts and approvals arrays are different lengths.
     * @param _accounts wallets or contract addresses to set approval
     */
    function _setCreatorAccess(address[] calldata _accounts, bool[] calldata _approvals) internal returns (bool) {
        ApplicationAccessStorage.Layout storage l = ApplicationAccessStorage.layout();

        if (_accounts.length != _approvals.length) {
            revert ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength();
        }

        for (uint256 i = 0; i < _accounts.length; i++) {
            l.approvedCreators[_accounts[i]] = _approvals[i];
        }
    }
}

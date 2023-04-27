// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IApplicationAccess {
    error ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength();
    error ApplicationAccess_notAuthorised();

    event CreatorAccessUpdated(address[] accounts, bool[] approvals);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IApplicationAccess {
    error ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength();
    error ApplicationAccess_notAuthorised();

    event CreatorAccessUpdated(address[] accounts, bool[] approvals);
}
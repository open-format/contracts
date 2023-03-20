// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IApplicationAccess {
    error ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength();
    error ApplicationAccess_notAuthorised();

    event setApplicationAccess(address[] _accounts, bool[] _approvals);
}

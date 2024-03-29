// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IDefaultOperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error DefaultOperatorFilterer_OperatorNotAllowed(address operator);
}

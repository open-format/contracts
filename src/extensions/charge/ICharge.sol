// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ICharge {
    error Charge_doNotHavePermission();

    event RequiredTokenBalanceUpdated(address token, uint256 balance);
    event ChargedUser(address user, address token, uint256 amount, bytes32 chargeId, bytes32 chargeType);
}

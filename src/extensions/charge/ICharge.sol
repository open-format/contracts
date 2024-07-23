// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ICharge {
    error Charge_doNotHavePermission();

    event minimumCreditBalanceUpdated(address credit, uint256 balance);
    event chargedUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType);
}

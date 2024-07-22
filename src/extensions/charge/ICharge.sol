// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface ICharge {
    event minimumCreditBalanceUpdated(address credit, uint256 balance);
    // Inspired by rewards events, adding a chargeId and chargeType for additional context
    // example -> chargeId  chargeId: "10tx" chargeType:"batch"
    event chargedUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType );

    error Charge_doNotHavePermission();
}

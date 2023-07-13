// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IFactory {
    error Factory_nameAlreadyUsed();
    error Factory_NotConstellationOwner();
    error Factory_InvalidConstellationContract();
    error Factory_NotAContractAddress();

    event Created(address id, address owner, string name, address constellationId);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IStar {
    error Factory_nameAlreadyUsed();
    error Factory_invalidConstellation();
    error Factory_notConstellationOwner();

    event Created(address id, address constellation, address owner, string name);
}

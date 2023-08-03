// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IConstellation {
    error Constellation_NameAlreadyUsed();
    error Constellation_InvalidToken();
    error Constellation_NotFoundOrNotOwner();

    event Created(address id, address owner, string name);
    event UpdatedToken(address oldTokenAddress, address newTokenAddress);
}

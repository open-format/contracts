// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IFactory {
    error Factory_nameAlreadyUsed();

    event Created(address id, address owner, string name);
}

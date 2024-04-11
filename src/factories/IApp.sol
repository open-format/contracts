// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IApp {
    error App_nameAlreadyUsed();

    event Created(address id, address owner, string name);
}

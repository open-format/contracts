// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IInitializable {
    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    error Initializable_contractIsInitializing();
    error Initializable_contractIsNotInitializing();
    error Initializable_contractIsAlreadyInitialized();
}

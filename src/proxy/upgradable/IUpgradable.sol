// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IUpgradable {
    /**
     * @notice query the address of the registry
     * @return registryAddress address of registry
     */

    function getRegistryAddress() external view returns (address registryAddress);
}

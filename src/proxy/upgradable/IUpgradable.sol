// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IUpgradable {
    /**
     * @notice query the address of the registry
     * @return registryAddress address of registry
     */

    function getRegistryAddress() external view returns (address registryAddress);

    /**
     * @notice set the address of the registry
     * @param registryAddress address of registry
     */

    function setRegistryAddress(address registryAddress) external;
}
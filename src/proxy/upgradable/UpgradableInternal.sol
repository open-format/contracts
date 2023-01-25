// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {UpgradableStorage} from "./UpgradableStorage.sol";

abstract contract UpgradableInternal {
    /**
     * @notice query the address of the registry
     * @return registryAddress address of registry
     */

    function _getRegistryAddress() internal view virtual returns (address registryAddress) {
        return UpgradableStorage.layout().registryAddress;
    }

    /**
     * @notice set the address of the registry
     * @param registryAddress address of registry
     */

    function _setRegistryAddress(address registryAddress) internal virtual {
        UpgradableStorage.layout().registryAddress = registryAddress;
    }
}

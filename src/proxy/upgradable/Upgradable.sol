// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IUpgradable} from "./IUpgradable.sol";
import {UpgradableStorage} from "./UpgradableStorage.sol";
import {UpgradableInternal} from "./UpgradableInternal.sol";

abstract contract Upgradable is IUpgradable, UpgradableInternal {
    /**
     * @notice query the address of the registry
     * @return registryAddress address of registry
     */

    function getRegistryAddress() external view returns (address registryAddress) {
        return _getRegistryAddress();
    }
}

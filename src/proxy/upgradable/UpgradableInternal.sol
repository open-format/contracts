// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {UpgradableStorage} from "./UpgradableStorage.sol";

abstract contract UpgradableInternal {
    function _getRegistryAddress() internal view virtual returns (address registryAddress) {
        return UpgradableStorage.layout().registryAddress;
    }

    function _setRegistryAddress(address registryAddress) internal virtual {
        UpgradableStorage.layout().registryAddress = registryAddress;
    }
}

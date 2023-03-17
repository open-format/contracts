// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {InitializableStorage} from "./InitializableStorage.sol";
import {IInitializable} from "./IInitializable.sol";

abstract contract InitializableInternal is IInitializable {
    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        InitializableStorage.Layout storage l = InitializableStorage.layout();
        if (l._initializing) {
            revert Initializable_contractIsInitializing();
        }

        if (l._initialized != type(uint8).max) {
            l._initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return InitializableStorage.layout()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return InitializableStorage.layout()._initializing;
    }

    function _setInitialized(uint8 _value) internal {
        InitializableStorage.layout()._initialized = _value;
    }

    function _setInitializing(bool _value) internal {
        InitializableStorage.layout()._initializing = _value;
    }
}

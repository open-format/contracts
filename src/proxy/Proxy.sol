// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";
import {ERC165Base, ERC165BaseStorage} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

import {IProxy} from "./IProxy.sol";
import {Readable} from "./readable/Readable.sol";

/**
 * @title "Open Format "Proxy" reference contract
 * @notice used to interact with open foramt
 */
abstract contract Proxy is IProxy, Readable, SafeOwnable, ERC165Base {
    constructor(address registry) {
        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC173).interfaceId, true);

        _setOwner(msg.sender);

        _setRegistryAddress(registry);
    }

    /**
     * @notice looks up implementation address and delegate all calls to implementation contract
     * @dev reverts if function selector is not in registry
     * @dev memory location in use by assembly may be unsafe in other contexts
     * @dev assembly code derived from @solidstate/contracts/proxy/Proxy.sol
     */

    fallback() external payable {
        address facet = _facetAddress(msg.sig);
        if (facet == address(0)) revert Error_FunctionSelectorNotFound();

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    receive() external payable {}

    function _transferOwnership(address account) internal virtual override(SafeOwnable) {
        super._transferOwnership(account);
    }
}

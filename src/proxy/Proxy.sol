// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {IOwnable, Ownable, OwnableInternal} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ISafeOwnable, SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";
import {ERC165Base, ERC165BaseStorage} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

import {IProxy} from "./IProxy.sol";
import {Upgradable, UpgradableInternal} from "./upgradable/Upgradable.sol";
import {Readable} from "./readable/Readable.sol";

/**
 * @title SolidState "Diamond" proxy reference implementation
 */
abstract contract Proxy is IProxy, Upgradable, Readable, SafeOwnable, ERC165Base {
    constructor() {
        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165
        _setSupportsInterface(type(IERC165).interfaceId, true);

        // register SafeOwnable
        _setSupportsInterface(type(IERC173).interfaceId, true);

        // set owner
        _setOwner(msg.sender);
    }

    fallback(bytes calldata data) external payable returns (bytes memory) {
        bytes4 selector = msg.sig;
        address facet = IDiamondReadable(_getRegistryAddress()).facetAddress(selector);

        if (facet == address(0)) revert FunctionSelectorNotFound();

        (bool ok, bytes memory resp) = facet.delegatecall(data);

        if (!ok) revert FunctionCallReverted();

        return resp;
    }

    receive() external payable {}

    function _transferOwnership(address account) internal virtual override(SafeOwnable, OwnableInternal) {
        super._transferOwnership(account);
    }
}

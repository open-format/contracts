// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";
import {ERC165Base, ERC165BaseStorage} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

import {IProxy} from "./IProxy.sol";
import {Readable} from "./readable/Readable.sol";

abstract contract Proxy is IProxy, Readable, SafeOwnable, ERC165Base {
    constructor(address registry) {
        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC173).interfaceId, true);

        _setOwner(msg.sender);

        _setRegistryAddress(registry);
    }

    fallback(bytes calldata data) external payable returns (bytes memory) {
        address facet = _facetAddress(msg.sig);
        if (facet == address(0)) revert FunctionSelectorNotFound();

        (bool ok, bytes memory resp) = facet.delegatecall(data);
        if (!ok) revert FunctionCallReverted();

        return resp;
    }

    receive() external payable {}

    function _transferOwnership(address account) internal virtual override(SafeOwnable) {
        super._transferOwnership(account);
    }
}

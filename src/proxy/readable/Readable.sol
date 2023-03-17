// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {UpgradableInternal} from "../upgradable/UpgradableInternal.sol";
import {ReadableInternal} from "./ReadableInternal.sol";

/**
 * @title Proxy Readable
 * @notice complies with EIP-2535 "Diamond" introspection by calling Registry contract
 */

abstract contract Readable is IDiamondReadable, UpgradableInternal, ReadableInternal {
    function facets() external view returns (Facet[] memory diamondFacets) {
        return IDiamondReadable(_getRegistryAddress()).facets();
    }

    function facetFunctionSelectors(address facet) external view returns (bytes4[] memory selectors) {
        return IDiamondReadable(_getRegistryAddress()).facetFunctionSelectors(facet);
    }

    function facetAddresses() external view returns (address[] memory addresses) {
        return IDiamondReadable(_getRegistryAddress()).facetAddresses();
    }

    function facetAddress(bytes4 selector) external view returns (address facet) {
        return _facetAddress(selector);
    }
}

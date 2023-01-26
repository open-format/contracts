// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {UpgradableInternal} from "../upgradable/UpgradableInternal.sol";
import {ReadableStorage} from "./ReadableStorage.sol";

abstract contract ReadableInternal is UpgradableInternal {
    function _facetAddress(bytes4 selector) internal view returns (address facet) {
        ReadableStorage.CachedFacet memory cachedFacet = ReadableStorage.layout().selectors[selector];
        if (cachedFacet.facet != address(0) && cachedFacet.timestamp > block.timestamp) {
            return cachedFacet.facet;
        }

        return IDiamondReadable(_getRegistryAddress()).facetAddress(selector);
    }
}

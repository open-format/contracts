// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {UpgradableInternal} from "../upgradable/UpgradableInternal.sol";
import {ReadableStorage} from "./ReadableStorage.sol";

abstract contract ReadableInternal is UpgradableInternal {
    /**
     * @dev checks storage before looking up on Registry contract
     * @dev note: a more gas optimised implementation may look like @solidstate/contract/proxy/diamond/base/DiamondBase.sol
     */

    function _facetAddress(bytes4 selector) internal view returns (address facet) {
        ReadableStorage.CachedFacet memory cachedFacet = ReadableStorage.layout().selectors[selector];

        // use case is unlikely to be gamed by miners
        // slither-disable-next-line timestamp
        if (cachedFacet.facet != address(0) && cachedFacet.timestamp > block.timestamp) {
            return cachedFacet.facet;
        }

        return IDiamondReadable(_getRegistryAddress()).facetAddress(selector);
    }
}

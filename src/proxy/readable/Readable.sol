// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {UpgradableInternal} from "../upgradable/UpgradableInternal.sol";

/**
 * @title SolidState "Diamond" proxy reference implementation
 */
abstract contract Readable is IDiamondReadable, UpgradableInternal, OwnableInternal {
    // register DiamondReadable
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
        return IDiamondReadable(_getRegistryAddress()).facetAddress(selector);
    }
}

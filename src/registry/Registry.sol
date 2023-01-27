// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Proxy, IProxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {SolidStateDiamond, ISolidStateDiamond} from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

import {IRegistry} from "./IRegistry.sol";

/**
 * @title Registry reference implementation
 * @notice essentially the same as solid state diamond but prevents and facet writing to the state
 */
abstract contract Registry is IRegistry, SolidStateDiamond {
    /**
     * @notice simply throws an error
     * @dev override proxy fallback to prevent delegating calls
     * @dev this is to prevent facets writing to registry storage through a delegate call
     */
    fallback() external payable override(Proxy, IProxy) {
        revert Error_CannotInteractWithRegistryDirectly();
    }

    /**
     * @notice allows owner to withdraw any ether sent
     * @dev prevents ether being locked up
     */

    function withdraw() public onlyOwner {
        payable(_owner()).transfer(address(this).balance);
    }
}

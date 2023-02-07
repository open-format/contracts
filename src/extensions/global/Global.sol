// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {GlobalInternal} from "./GlobalInternal.sol";
/**
 * @title Global Facet
 * @notice This allows inherited contract to get/set global address in diamond storage
 * @dev the global address is a contract that holds glabl state that should be the same for every proxy
 */

abstract contract Global is GlobalInternal {}

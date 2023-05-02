// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {GlobalInternal} from "./GlobalInternal.sol";
/**
 * @title Global Facet
 * @notice This allows inherited contract to get/set global address in diamond storage
 * @dev the global address is a contract that holds global state that should be the same for every proxy
 */

abstract contract Global is GlobalInternal {}

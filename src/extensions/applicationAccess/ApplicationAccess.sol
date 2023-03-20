// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IApplicationAccess} from "./IApplicationAccess.sol";
import {ApplicationAccessInternal} from "./ApplicationAccessInternal.sol";

abstract contract ApplicationAccess is IApplicationAccess, ApplicationAccessInternal {}

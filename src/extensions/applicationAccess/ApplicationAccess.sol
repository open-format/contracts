// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IApplicationAccess} from "./IApplicationAccess.sol";
import {ApplicationAccessInternal} from "./ApplicationAccessInternal.sol";

abstract contract ApplicationAccess is IApplicationAccess, ApplicationAccessInternal {}

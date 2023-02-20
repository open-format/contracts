// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IPlatformFee} from "./IPlatformFee.sol";
import {PlatformFeeInternal} from "./PlatformFeeInternal.sol";

abstract contract PlatformFee is IPlatformFee, PlatformFeeInternal {}

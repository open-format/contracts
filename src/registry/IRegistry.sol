// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import {ISolidStateDiamond} from "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";

interface IRegistry is ISolidStateDiamond {
    error Registry_cannotInteractWithRegistryDirectly();
}

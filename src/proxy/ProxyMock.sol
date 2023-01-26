// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Proxy} from "./Proxy.sol";

contract ProxyMock is Proxy {
    /**
     * @dev inherits proxy constructor
     */
    constructor(address registry) Proxy(registry) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Proxy} from "./Proxy.sol";

contract ProxyMock is Proxy {
    /**
     * @dev override constructor that disablesInitializers with one that calls innit
     */
    constructor(address _registry, address _globals) Proxy(false) {
        init(msg.sender, _registry, _globals);
    }
}

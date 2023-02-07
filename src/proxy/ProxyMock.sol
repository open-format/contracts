// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Proxy} from "./Proxy.sol";

contract ProxyMock is Proxy {
    /**
     * @dev override constructer that disablesInitilizers with one that calls innit
     */
    constructor(address _registry, address _globals) Proxy(false) {
        innit(msg.sender, _registry, _globals);
    }
}

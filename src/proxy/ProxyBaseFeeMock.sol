// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ProxyBaseFee} from "./ProxyBaseFee.sol";

contract ProxyBaseFeeMock is ProxyBaseFee {
    /**
     * @dev override constructer that disablesInitilizers with one that calls innit
     */
    constructor(address _registry, address _globals) ProxyBaseFee(false) {
        init(msg.sender, _registry, _globals);
    }
}

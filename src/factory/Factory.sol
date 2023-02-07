// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {Proxy} from "../proxy/Proxy.sol";
// WIP experimenting with minimal clone factory to see how to use it
// TODO: test with intergration
// TODO: see if it can be refactored and used as a facet in a diamond
// TODO: look into vanity addresses

// salt could be hash of msg.sender and app name? avoiding all conflicts?

contract Factory is MinimalProxyFactory, Ownable {
    address public template;
    address public registry;
    address public globals;

    // store created apps
    mapping(bytes32 => address) apps; // salt => deployment addres

    constructor(address _template, address _registry, address _globals) {
        _setOwner(msg.sender);
        template = _template;
        registry = _registry;
        globals = _globals;
    }

    function create(bytes32 _salt) external returns (address appAddress) {
        // TODO: WIP need to see other examples of factorys and handerling salt
        // check proxy not already deployed
        if (apps[_salt] != address(0)) {
            revert("salt already used");
        }

        // deploys new proxy using CREATE2
        appAddress = _deployMinimalProxy(template, _salt);
        Proxy(payable(appAddress)).innit(msg.sender, registry, globals);

        apps[_salt] = appAddress;
    }

    function setTemplate(address _template) public onlyOwner {
        template = _template;
    }

    function setRegistry(address _registry) public onlyOwner {
        registry = _registry;
    }

    function setGlobals(address _globals) public onlyOwner {
        registry = _globals;
    }
}

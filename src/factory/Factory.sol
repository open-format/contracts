// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {Proxy} from "../proxy/Proxy.sol";
// WIP experimenting with minimal clone factory to see how to use it

/**
 * @title "App Factory"
 * @notice (WIP) a factory contract for creating proxy(app) contracts
 * @dev    deploys minimal proxys that point to Proxy implementation/template
 *         is designed to be deployed sepertly from the registry and manged by open-format
 */
contract Factory is MinimalProxyFactory, Ownable {
    event created(address id, address owner);

    address public template;
    address public registry;
    address public globals;

    // store created apps
    mapping(bytes32 => address) apps; // salt => deployment address

    constructor(address _template, address _registry, address _globals) {
        _setOwner(msg.sender);
        template = _template;
        registry = _registry;
        globals = _globals;
    }

    /**
     * @dev _salt param can be thought as the app id
     */
    function create(bytes32 _salt) external returns (address id) {
        // TODO: WIP need to see other examples of factorys and handerling salt
        // check proxy not already deployed
        if (apps[_salt] != address(0)) {
            revert("salt already used");
        }

        apps[_salt] = id;

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(template, _salt);
        Proxy(payable(id)).innit(msg.sender, registry, globals);

        emit created(id, msg.sender);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import {IFactory} from "./IFactory.sol";
import {Proxy} from "../proxy/Proxy.sol";
// WIP experimenting with minimal clone factory to see how to use it

/**
 * @title "App Factory"
 * @notice (WIP) a factory contract for creating proxy(app) contracts
 * @dev    deploys minimal proxies that point to Proxy implementation/template
 *         is designed to be deployed separately from the registry and managed by open-format
 */
contract Factory is IFactory, MinimalProxyFactory, Ownable {
    address public template;
    address public registry;
    address public globals;

    // store created apps
    mapping(bytes32 => address) public apps; // salt => deployment address

    constructor(address _template, address _registry, address _globals) {
        _setOwner(msg.sender);
        template = _template;
        registry = _registry;
        globals = _globals;
    }

    /**
     * @dev _salt param can be thought as the app id
     */
    function create(bytes32 _name) external returns (address id) {
        // check proxy not already deployed
        if (apps[_name] != address(0)) {
            revert Factory_nameAlreadyUsed();
        }

        // deploy new proxy using CREATE2
        id = _deployMinimalProxy(template, _name);
        apps[_name] = id;

        Proxy(payable(id)).init(msg.sender, registry, globals);

        emit Created(id, msg.sender, string(abi.encodePacked(_name)));
    }

    /**
     * @notice returns the deterministic deployment address for app
     * @dev    The contract deployed is a minimal proxy pointing to the app template
     * @return deploymentAddress the address of the app
     */
    function calculateDeploymentAddress(bytes32 _name) external view returns (address) {
        // check proxy not already deployed
        if (apps[_name] != address(0)) {
            revert Factory_nameAlreadyUsed();
        }

        return _calculateMinimalProxyDeploymentAddress(template, _name);
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

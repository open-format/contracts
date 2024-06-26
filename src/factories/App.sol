// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import {IApp} from "./IApp.sol";
import {Proxy} from "../proxy/Proxy.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {ERC20Base} from "../tokens/ERC20/ERC20Base.sol";

/**
 * @title "App Factory"
 * @notice  A contract for creating proxy (app) contracts.
 *          This contract deploys minimal proxies that point to a Proxy implementation/template
 *          and is designed to be deployed separately from the registry and managed by Open Format.
 */
contract AppFactory is IApp, MinimalProxyFactory, Ownable {
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
    function create(bytes32 _name, address _owner) external returns (address id) {
        bytes32 salt = keccak256(abi.encode(_owner, _name));

        // check proxy not already deployed
        if (apps[salt] != address(0)) {
            revert App_nameAlreadyUsed();
        }

        // deploy new proxy using CREATE2
        id = _deployMinimalProxy(template, salt);
        apps[salt] = id;

        Proxy(payable(id)).init(_owner, registry, globals);

        emit Created(id, _owner, string(abi.encodePacked(_name)));
    }

    /**
     * @notice returns the deterministic deployment address for a stsar
     * @dev    The contract deployed is a minimal proxy pointing to the app template
     * @return deploymentAddress the address of the app
     */
    function calculateDeploymentAddress(address _account, bytes32 _name) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(_account, _name));
        // check proxy not already deployed
        if (apps[salt] != address(0)) {
            revert App_nameAlreadyUsed();
        }

        return _calculateMinimalProxyDeploymentAddress(template, salt);
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

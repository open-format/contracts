// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import {IFactory} from "./IFactory.sol";
import {Proxy} from "../proxy/Proxy.sol";
import {ERC20Constellation} from "../tokens/ERC20/ERC20Constellation.sol";
import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";
import {ERC20Factory} from "../extensions/ERC20Factory/ERC20Factory.sol";

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));

/**
 * @title "App Factory"
 * @notice  A contract for creating proxy (app) contracts.
 *          This contract deploys minimal proxies that point to a Proxy implementation/template
 *          and is designed to be deployed separately from the registry and managed by Open Format.
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

    function create(bytes32 _name, address _constellation_id, address _owner) external returns (address id) {
        bytes32 salt = keccak256(abi.encode(_owner, _name));
        bytes32 implementationId = keccak256(abi.encodePacked("Constellation"));

        // check if _owner is the _owner of the given Constellation
        if (!ERC20Constellation(_constellation_id).hasRole(ADMIN_ROLE, _owner)) {
            revert Factory_NotConstellationOwner();
        }

        // check if _constellation_id is a contract not a EOA
        if (!AddressUtils.isContract(_constellation_id)) {
            revert Factory_NotAContractAddress();
        }

        // check if _constellation_id is a valid constellation implementation
        if (!ERC20Constellation(_constellation_id).validConstellation(implementationId)) {
            revert Factory_InvalidConstellationContract();
        }

        // check proxy not already deployed
        if (apps[salt] != address(0)) {
            revert Factory_nameAlreadyUsed();
        }

        // deploy new proxy using CREATE2
        id = _deployMinimalProxy(template, salt);
        apps[salt] = id;

        Proxy(payable(id)).init(_owner, registry, globals);

        emit Created(id, _owner, string(abi.encodePacked(_name)), _constellation_id);
    }

    /**
     * @notice returns the deterministic deployment address for app
     * @dev    The contract deployed is a minimal proxy pointing to the app template
     * @return deploymentAddress the address of the app
     */
    function calculateDeploymentAddress(address _account, bytes32 _name) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(_account, _name));
        // check proxy not already deployed
        if (apps[salt] != address(0)) {
            revert Factory_nameAlreadyUsed();
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

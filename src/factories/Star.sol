// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import {IStar} from "./IStar.sol";
import {Proxy} from "../proxy/Proxy.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {ConstellationERC20Base} from "../tokens/ERC20/ConstellationERC20Base.sol";

/**
 * @title "Star Factory"
 * @notice  A contract for creating proxy (star) contracts.
 *          This contract deploys minimal proxies that point to a Proxy implementation/template
 *          and is designed to be deployed separately from the registry and managed by Open Format.
 */
contract StarFactory is IStar, MinimalProxyFactory, Ownable {
    address public template;
    address public registry;
    address public globals;

    // store created stars
    mapping(bytes32 => address) public stars; // salt => deployment address

    constructor(address _template, address _registry, address _globals) {
        _setOwner(msg.sender);
        template = _template;
        registry = _registry;
        globals = _globals;
    }

    /**
     * @dev _salt param can be thought as the star id
     */
    function create(bytes32 _name, address _constellation, address _owner) external returns (address id) {
        bytes32 salt = keccak256(abi.encode(_owner, _name));

        // check proxy not already deployed
        if (stars[salt] != address(0)) {
            revert Factory_nameAlreadyUsed();
        }

        // check _constellation address is a valid ERC20
        if (!IERC165(_constellation).supportsInterface(type(IERC20).interfaceId)) {
            revert Factory_invalidConstellation();
        }

        if (!ConstellationERC20Base(_constellation).hasRole(bytes32(uint256(0)), msg.sender)) {
            revert Factory_notConstellationOwner();
        }

        // deploy new proxy using CREATE2
        id = _deployMinimalProxy(template, salt);
        stars[salt] = id;

        Proxy(payable(id)).init(_owner, registry, globals);

        emit Created(id, _constellation, _owner, string(abi.encodePacked(_name)));
    }

    /**
     * @notice returns the deterministic deployment address for a stsar
     * @dev    The contract deployed is a minimal proxy pointing to the star template
     * @return deploymentAddress the address of the star
     */
    function calculateDeploymentAddress(address _account, bytes32 _name) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(_account, _name));
        // check proxy not already deployed
        if (stars[salt] != address(0)) {
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

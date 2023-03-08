// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

import {IERC20Factory} from "./IERC20Factory.sol";
import {ERC20FactoryInternal} from "./ERC20FactoryInternal.sol";

/**
 * @dev ERC20 implementations must have an initialize function
 */
interface CompatibleERC20Implementation {
    // forgefmt: disable-next-item
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 supply
    ) external;
}

/**
 * @title   "ERC20Factory Extension"
 * @notice  (WIP) a factory contract for creating ECR20 contracts
 * @dev     deploys minimal proxies that point to ERC20Base implementation
 *          compatible to be inherited by facet contract
 *          there is an internal dependency on the globals extension.
 * @dev     inheriting contracts must override the internal _canCreate function
 */

abstract contract ERC20Factory is IERC20Factory, ERC20FactoryInternal, MinimalProxyFactory, ReentrancyGuard {
    /**
     * @notice creates an erc20 contract based on implementation
     * @dev the hash of the name is used as a "salt" so each contract is deployed to a different address
     *      the deployed contract is a minimal proxy that points to the implementation chosen
     * @param _name the name of the erc20 contract
     * @param _symbol the symbol of the erc20 contract
     * @param _decimals the decimals for currency
     * @param _supply the initial minted supply, mints to caller
     * @param _implementationId the chosen implementation of erc20 contract
     */
    function createERC20(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes32 _implementationId
    ) external virtual nonReentrant returns (address id) {
        if (!_canCreate()) {
            revert Error_do_not_have_permission();
        }

        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert Error_no_implementation_found();
        }

        bytes32 salt = keccak256(abi.encode(_name));

        // check proxy has not deployed erc20 with the same name
        // deploying with the same salt would override that ERC20
        if (_getId(salt) != address(0)) {
            revert Error_name_already_used();
        }

        // hook to add functionality before create
        _beforeCreate();

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(implementation, salt);

        // saves deployment for checking later
        _setId(salt, id);

        // initialize ERC20 contract
        try CompatibleERC20Implementation(payable(id)).initialize(msg.sender, _name, _symbol, _decimals, _supply) {
            emit Created(id, msg.sender, _name, _symbol, _decimals, _supply);
        } catch {
            revert Error_failed_to_initialize();
        }
    }

    function getERC20FactoryImplementation(bytes32 _implementationId) external view returns (address) {
        return _getImplementation(_implementationId);
    }
}

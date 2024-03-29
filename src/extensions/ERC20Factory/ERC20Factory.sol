// SPDX-License-Identifier: BUSL-1.1
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
        uint256 _supply,
        bytes memory _data
    ) external;
}

/**
 * @title   "ERC20Factory Extension"
 * @notice  A factory contract for creating ECR20 contracts
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
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes32 _implementationId
    ) external payable virtual nonReentrant returns (address id) {
        if (!_canCreate()) {
            revert ERC20Factory_doNotHavePermission();
        }

        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert ERC20Factory_noImplementationFound();
        }

        // hook to add functionality before create
        _beforeCreate();

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(implementation, _getSalt(msg.sender));
        _increaseContractCount(msg.sender);

        // add the app address and globals as encoded data
        // this enables ERC20 contracts to grant minter role to the app and pay platform fee's
        bytes memory data = abi.encode(address(this), _getGlobalsAddress());

        // initialize ERC20 contract
        try CompatibleERC20Implementation(payable(id)).initialize(msg.sender, _name, _symbol, _decimals, _supply, data)
        {
            emit Created(id, msg.sender, _name, _symbol, _decimals, _supply, _implementationId);
        } catch {
            revert ERC20Factory_failedToInitialize();
        }
    }

    function getERC20FactoryImplementation(bytes32 _implementationId) external view returns (address) {
        return _getImplementation(_implementationId);
    }

    /**
     * @notice returns the deterministic deployment address of ERC20 contract based on the name an implementation chosen
     * @dev    The contract deployed is a minimal proxy pointing to the implementation
     * @return deploymentAddress the address the erc20 contract will be deployed to
     */
    function calculateERC20FactoryDeploymentAddress(bytes32 _implementationId) external view returns (address) {
        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert ERC20Factory_noImplementationFound();
        }

        return _calculateMinimalProxyDeploymentAddress(implementation, _getSalt(msg.sender));
    }
}

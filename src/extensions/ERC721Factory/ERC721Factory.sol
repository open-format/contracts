// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

import {IERC721Factory} from "./IERC721Factory.sol";
import {ERC721FactoryInternal} from "./ERC721FactoryInternal.sol";

/**
 * @dev ERC721 implementations must have an initialize function
 */
interface CompatibleERC721Implementation {
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        bytes memory _data
    ) external;
}

/**
 * @title   "ERC721Factory Extension"
 * @notice  A factory contract extension for creating clones of ECR721 contracts
 * @dev     deploys minimal proxy that point to ERC721 implementation
 *          compatible to be inherited by facet contract
 *          there is an internal dependency on the globals extension.
 * @dev     inheriting contracts must override the internal _canCreate function
 */

abstract contract ERC721Factory is IERC721Factory, ERC721FactoryInternal, MinimalProxyFactory, ReentrancyGuard {
    /**
     * @notice creates an erc721 contract based on implementation
     * @dev the deployed contract is a minimal proxy that points to the implementation chosen
     * @param _name the name of the ERC721 contract
     * @param _symbol the symbol of the ERC721 contract
     * @param _royaltyRecipient the default address that royalties are sent to
     * @param _royaltyBps the default royalty percent in BPS
     * @param _implementationId the chosen implementation of ERC721 contract
     */
    function createERC721(
        string calldata _name,
        string calldata _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        bytes32 _implementationId
    ) external payable virtual nonReentrant returns (address id) {
        if (!_canCreate()) {
            revert ERC721Factory_doNotHavePermission();
        }

        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert ERC721Factory_noImplementationFound();
        }

        // hook to add functionality before create
        _beforeCreate();

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(implementation, _getSalt(msg.sender));
        _increaseContractCount(msg.sender);

        // add the app address as encoded data, mainly intended for auto granting minter role
        bytes memory data = abi.encode(address(this));

        // initialize ERC721 contract
        try CompatibleERC721Implementation(payable(id)).initialize(
            msg.sender, _name, _symbol, _royaltyRecipient, _royaltyBps, data
        ) {
            emit Created(id, msg.sender, _name, _symbol, _royaltyRecipient, _royaltyBps, _implementationId);
        } catch {
            revert ERC721Factory_failedToInitialize();
        }
    }

    function getERC721FactoryImplementation(bytes32 _implementationId) external view returns (address) {
        return _getImplementation(_implementationId);
    }

    /**
     * @notice returns the deterministic deployment address for ERC721 contracts based on the name an implementation chosen
     * @dev    The contract deployed is a minimal proxy pointing to the implementation
     * @return deploymentAddress the address the erc20 contract will be deployed to
     */
    function calculateERC721FactoryDeploymentAddress(bytes32 _implementationId) external view returns (address) {
        address implementation = _getImplementation(_implementationId);
        if (implementation == address(0)) {
            revert ERC721Factory_noImplementationFound();
        }

        return _calculateMinimalProxyDeploymentAddress(implementation, _getSalt(msg.sender));
    }
}

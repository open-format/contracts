// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {ERC721Base} from "../../tokens/ERC721/ERC721Base.sol";

import {ERC721FactoryInternal} from "./ERC721FactoryInternal.sol";

/**
 * @dev this is structured as a facet to be added to registry contract
 *      there is an internal dependency on the globals extension.
 */

abstract contract ERC721Factory is ERC721FactoryInternal, MinimalProxyFactory {
    // TODO: add onlyOwner modifyer or could extend with a _canDeploy role
    function createERC721(string memory _name, string memory _symbol, address _royaltyRecipient, uint16 _royaltyBps)
        external
        returns (address deployment)
    {
        address implementation = _getImplementation();
        if (implementation == address(0)) {
            revert("no implementation found");
        }

        bytes32 salt = keccak256(abi.encode(_name));
        // TODO: WIP need to see other examples of factorys and handerling salt
        // check proxy not already deployed
        if (_getDeployment(salt) != address(0)) {
            revert("name already used");
        }

        // deploys new proxy using CREATE2
        deployment = _deployMinimalProxy(implementation, salt);
        ERC721Base(payable(deployment)).initialize(_name, _symbol, _royaltyRecipient, _royaltyBps);

        _setDeployment(salt, deployment);
    }

    function getERC721FactoryImplementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {ERC721Base} from "../../tokens/ERC721/ERC721Base.sol";

import {IERC721Factory} from "./IERC721Factory.sol";
import {ERC721FactoryInternal} from "./ERC721FactoryInternal.sol";

/**
 * @title   "ERC721Factory Extension"
 * @notice  (WIP) a factory contract for creating ECR721 contracts
 * @dev     deploys minimal proxys that point to ERC721Base implementation
 *          compatible to be inherited by facet contract
 *          there is an internal dependency on the globals extension.
 * @dev     inheriting contracts must override the internal _canCreate function
 */

abstract contract ERC721Factory is IERC721Factory, ERC721FactoryInternal, MinimalProxyFactory {
    function createERC721(string memory _name, string memory _symbol, address _royaltyRecipient, uint16 _royaltyBps)
        external
        virtual
        returns (address id)
    {
        if (!_canCreate()) {
            revert("do not have permission to create");
        }

        address implementation = _getImplementation();
        if (implementation == address(0)) {
            revert("no implementation found");
        }

        // TODO: WIP need to see other examples of factorys and handerling salt
        bytes32 salt = keccak256(abi.encode(_name));
        // check proxy has not deployed erc721 with the same name
        // deploying with the same salt would override that ERC721
        if (_getId(salt) != address(0)) {
            revert("name already used");
        }

        // saves deployment for checking later
        _setId(salt, id);

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(implementation, salt);
        ERC721Base(payable(id)).initialize(_name, _symbol, _royaltyRecipient, _royaltyBps);

        emit created(id, msg.sender, _name, _symbol, _royaltyRecipient, _royaltyBps);
    }

    function getERC721FactoryImplementation() external view returns (address) {
        return _getImplementation();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import {ERC20Base} from "../../tokens/ERC20/ERC20Base.sol";

import {IERC20Factory} from "./IERC20Factory.sol";
import {ERC20FactoryInternal} from "./ERC20FactoryInternal.sol";

/**
 * @title   "ERC20Factory Extension"
 * @notice  (WIP) a factory contract for creating ECR20 contracts
 * @dev     deploys minimal proxies that point to ERC20Base implementation
 *          compatible to be inherited by facet contract
 *          there is an internal dependency on the globals extension.
 * @dev     inheriting contracts must override the internal _canCreate function
 */

abstract contract ERC20Factory is IERC20Factory, ERC20FactoryInternal, MinimalProxyFactory {
    function createERC20(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply)
        external
        payable
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

        // TODO: WIP need to see other examples of factories and handling salt
        bytes32 salt = keccak256(abi.encode(_name));
        // check proxy has not deployed erc20 with the same name
        // deploying with the same salt would override that ERC20
        if (_getId(salt) != address(0)) {
            revert("name already used");
        }

        // saves deployment for checking later
        _setId(salt, id);

        // hook to add functionality before create
        _beforeCreate();

        // deploys new proxy using CREATE2
        id = _deployMinimalProxy(implementation, salt);
        ERC20Base(payable(id)).initialize(msg.sender, _name, _symbol, _decimals, _supply);

        emit Created(id, msg.sender, _name, _symbol, _decimals, _supply);
    }

    function getERC20FactoryImplementation() external view returns (address) {
        return _getImplementation();
    }
}

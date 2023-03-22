// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {ERC20FactoryStorage} from "./ERC20FactoryStorage.sol";
import {Global} from "../../extensions/global/Global.sol";

abstract contract ERC20FactoryInternal is Global {
    function _getImplementation(bytes32 _implementationId) internal view virtual returns (address) {
        return _getGlobals().getERC20Implementation(_implementationId);
    }

    /**
     * @dev hash of address and the number of created contracts from that address
     */
    function _getSalt(address _account) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_account, _getContractCount(_account)));
    }

    function _getContractCount(address _account) internal view virtual returns (uint256) {
        return ERC20FactoryStorage.layout().contractCount[_account];
    }

    function _increaseContractCount(address _account) internal virtual {
        ERC20FactoryStorage.layout().contractCount[_account]++;
    }

    function _canCreate() internal view virtual returns (bool);

    /**
     * @dev override to add functionality before create
     */
    function _beforeCreate() internal virtual {}
}

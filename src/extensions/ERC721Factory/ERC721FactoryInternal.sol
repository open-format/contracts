// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ERC721FactoryStorage} from "./ERC721FactoryStorage.sol";
import {Global} from "../../extensions/global/Global.sol";

abstract contract ERC721FactoryInternal is Global {
    function _getImplementation(bytes32 _implementationId) internal view returns (address) {
        return _getGlobals().getERC721Implementation(_implementationId);
    }

    /**
     * @dev hash of address and the number of created contracts from that address
     */
    function _getSalt(address _account) internal view virtual returns (bytes32) {
        return keccak256(abi.encode(_account, _getContractCount(_account)));
    }

    function _getContractCount(address _account) internal view virtual returns (uint256) {
        return ERC721FactoryStorage.layout().contractCount[_account];
    }

    function _increaseContractCount(address _account) internal virtual {
        ERC721FactoryStorage.layout().contractCount[_account]++;
    }

    function _canCreate() internal view virtual returns (bool);
    /**
     * @dev hook can be overridden to add functionality before create
     */
    function _beforeCreate() internal virtual {}
}

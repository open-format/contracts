// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {LazyMintStorage} from "./LazyMintStorage.sol";

abstract contract LazyMintInternal {
    function _getNextTokenIdToLazyMint() internal view virtual returns (uint256) {
        return LazyMintStorage.layout().nextTokenIdToLazyMint;
    }

    function _setNextTokenIdToLazyMint(uint256 id) internal virtual {
        LazyMintStorage.layout().nextTokenIdToLazyMint = id;
    }
}

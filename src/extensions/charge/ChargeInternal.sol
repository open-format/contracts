// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ChargeStorage} from "./ChargeStorage.sol";
import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

abstract contract ChargeInternal {
    function _hasFunds(address user, address token, uint256 requiredBalance) internal view returns (bool) {
        return (
            IERC20(token).balanceOf(user) >= requiredBalance
                && IERC20(token).allowance(user, address(this)) >= requiredBalance
        );
    }

    function _getRequiredTokenBalance(address token) internal view returns (uint256) {
        return ChargeStorage.layout().requiredTokenBalance[token];
    }

    function _setRequiredTokenBalance(address token, uint256 amount) internal {
        ChargeStorage.layout().requiredTokenBalance[token] = amount;
    }

    /**
     * @dev Internal function to get the address of the operator.
     * @return address The address of the operator.
     */
    function _operator() internal virtual returns (address) {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ChargeStorage} from "./ChargeStorage.sol";
import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

abstract contract ChargeInternal {
    function _hasFunds(address user, address credit, uint256 minimumBalance) internal view returns (bool) {
        return (
            IERC20(credit).balanceOf(user) >= minimumBalance
                && IERC20(credit).allowance(user, address(this)) >= minimumBalance
        );
    }

    function _getMinimumCreditBalance(address credit) internal view returns (uint256) {
        return ChargeStorage.layout().minimumCreditBalance[credit];
    }

    function _setMinimumCreditBalance(address credit, uint256 amount) internal {
        ChargeStorage.layout().minimumCreditBalance[credit] = amount;
    }

    /**
     * @dev Internal function to get the address of the operator.
     * @return address The address of the operator.
     */
    function _operator() internal virtual returns (address) {}
}

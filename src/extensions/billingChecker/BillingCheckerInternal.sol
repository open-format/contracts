// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Global} from "../global/Global.sol";
import {IBillingChecker} from "./IBillingChecker.sol";
import {IBilling} from "../../billing/IBilling.sol";

abstract contract BillingCheckerInternal is IBillingChecker, Global {
    /**
     * @dev wrapper that calls hasPaid from billing contract configured in Globals contract
     */
    function _hasPaid(address _app) internal view returns (bool) {
        address billingContract = _getGlobals().getBillingContract();
        if ( billingContract == address(0) ) {
            return false;
        }
        return IBilling(billingContract).hasPaid(_app);
    }
}

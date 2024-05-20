// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IBillingChecker} from "./IBillingChecker.sol";
import {BillingCheckerInternal} from "./BillingCheckerInternal.sol";

abstract contract BillingChecker is IBillingChecker, BillingCheckerInternal {
    /**
     *   @inheritdoc IBillingChecker
     */
    function hasPaid(address _app) external view returns (bool) {
        return _hasPaid(_app);
    }
}

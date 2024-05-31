// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IBillingChecker {
    /**
     * @notice Returns whether the app has paid all bills  
     * @param _app the app to check
     */
    function hasPaid(address _app) external view returns (bool);
}

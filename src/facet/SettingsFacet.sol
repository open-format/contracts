// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationAccess, IApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {Global} from "../extensions/global/Global.sol";

/**
 * @title   "Settings Facet"
 * @notice  A facet of the Settings contract that allows the application owner to manage application-wide settings.
 *          This contract includes extensions for SafeOwnable, and ApplicationAccess,
 *          which provide functionality for ownership management, and restricted
 *          access to contract creation.
 */

contract SettingsFacet is SafeOwnable, Global, ApplicationAccess {
    /**
     * @notice sets the approved accounts that have access to create new token contracts,
     *         setting the zero address will open it up to all.
     * @dev    the arrays of currencies and approvals must be the same length, emits CreatorAccessUpdated event
     * @param  accounts the list of accounts to edit
     * @param  approvals the list of approvals for the given accounts
     */
    function setCreatorAccess(address[] calldata accounts, bool[] calldata approvals) external onlyOwner {
        _setCreatorAccess(accounts, approvals);
    }

    /**
     * @notice checks if account has creator access for the application
     * @param  account the list of accounts to edit
     */
    function hasCreatorAccess(address account) external view returns (bool) {
        return _hasCreatorAccess(account);
    }

    /**
     * @notice gets the address of the globals contract
     */
    function getGlobalsAddress() external view returns (address) {
        return _getGlobalsAddress();
    }

    /**
     * @dev use safeOwnable for _transferOwnership instead of Ownable
     */
    function _transferOwnership(address account) internal override(OwnableInternal, SafeOwnable) {
        SafeOwnable._transferOwnership(account);
    }
}

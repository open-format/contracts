// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationFee} from "../extensions/applicationFee/ApplicationFee.sol";
import {ApplicationAccess, IApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {PlatformFee} from "../extensions/platformFee/PlatformFee.sol";
import {IVersionable} from "../extensions/versionable/IVersionable.sol";

/**
 * @title   "Settings Facet"
 * @notice  A facet of the Settings contract that allows the application owner to manage application-wide settings.
 *          This contract includes extensions for ApplicationFee, PlatformFee, SafeOwnable, and ApplicationAccess,
 *          which provide functionality for managing application and platform fees, ownership management, and restricted
 *          access to contract creation.
 */
contract SettingsFacet is ApplicationFee, PlatformFee, SafeOwnable, ApplicationAccess, IVersionable {
    string public constant FACET_VERSION = "1.0.0";
    string public constant FACET_NAME = "SettingsFacet";

    /**
     * @dev Override to return facet version.
     * @return version This facet version.
     */
    function facetVersion() external pure override returns (string memory) {
        return FACET_VERSION;
    }

    /**
     * @dev Override to return facet name.
     * @return name This facet name.
     */
    function facetName() external pure override returns (string memory) {
        return FACET_NAME;
    }

    /**
     * @notice sets the application percentage fee in BPS and the recipient wallet
     * @param percentBPS The percentage used to calculate application fee
     * @param recipient The wallet or contract address to send the application fee to
     */
    function setApplicationFee(uint16 percentBPS, address recipient) external onlyOwner {
        _setApplicationFee(percentBPS, recipient);
    }

    /**
     * @notice sets the accepted currencies for the application fee
     * @dev the arrays of currencies and approvals must be the same length
     * @param currencies the list of currencies to edit
     * @param approvals the list of approvals for the given currencies
     */
    function setAcceptedCurrencies(address[] memory currencies, bool[] memory approvals) external onlyOwner {
        _setAcceptedCurrencies(currencies, approvals);
    }

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

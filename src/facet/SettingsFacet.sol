// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {ApplicationFee} from "../extensions/applicationFee/ApplicationFee.sol";

/**
 * @title   "Settings Facet"
 * @notice  (WIP) allows app owner to manage application wide settings
 */

contract SettingsFacet is ApplicationFee, SafeOwnable {
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
}

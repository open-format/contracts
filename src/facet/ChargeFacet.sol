// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {Charge} from "../extensions/charge/Charge.sol";

/**
 * @title ChargeFacet
 * @dev This facet contract inherits from the Charge contract and sets the operator as the contract owner.
 */
contract ChargeFacet is Charge, Ownable {
    /**
     * @dev Override to set the operator to the app owner.
     * @return address The address of the owner, which acts as the operator.
     */
    function _operator() internal view override returns (address) {
        return _owner();
    }
}

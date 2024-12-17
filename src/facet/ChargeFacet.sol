// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {Charge} from "../extensions/charge/Charge.sol";
import {IVersionable} from "../extensions/versionable/IVersionable.sol";

/**
 * @title ChargeFacet
 * @dev This facet contract inherits from the Charge contract and sets the operator as the contract owner.
 */
contract ChargeFacet is Charge, Ownable, IVersionable {
    string public constant FACET_VERSION = "1.0.0";
    string public constant FACET_NAME = "ChargeFacet";

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
     * @dev Override to set the operator to the app owner.
     * @return address The address of the owner, which acts as the operator.
     */
    function _operator() internal view override returns (address) {
        return _owner();
    }
}

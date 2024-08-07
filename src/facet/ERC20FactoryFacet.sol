// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ERC20Factory} from "../extensions/ERC20Factory/ERC20Factory.sol";
import {ApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";

/**
 * @title   "ERC20Factory Facet"
 * @notice  A facet of the ERC20Factory contract that provides functionality for creating new ERC20 tokens.
 *          This contract also includes extensions for Ownable and ApplicationAccess, which allow for ownership management
 *          and restricted access to contract creation, respectively.
 */

contract ERC20FactoryFacet is ERC20Factory, Ownable, ApplicationAccess {
    /**
     * @dev uses applicationAccess extension for create access for new erc20 contracts
     */
    function _canCreate() internal view override returns (bool) {
        return _hasCreatorAccess(msg.sender);
    }
}

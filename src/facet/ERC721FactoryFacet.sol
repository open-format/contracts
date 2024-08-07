// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {ApplicationAccess} from "../extensions/applicationAccess/ApplicationAccess.sol";
import {ERC721Factory} from "../extensions/ERC721Factory/ERC721Factory.sol";

/**
 * @title   "ERC721Factory Facet"
 * @notice  A facet of the ERC721Factory contract that provides functionality for creating new ERC721 tokens.
 *          This contract also includes extensions for Ownable, and ApplicationAccess, which allow for ownership management
 *          and restricted access to contract creation, respectively.
 */

contract ERC721FactoryFacet is ERC721Factory, Ownable, ApplicationAccess {
    /**
     * @dev uses applicationAccess extension for create access for new erc721 contracts
     */
    function _canCreate() internal view override returns (bool) {
        return _hasCreatorAccess(msg.sender);
    }
}

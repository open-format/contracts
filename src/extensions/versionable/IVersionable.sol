// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";

/**
 *  Utility extension to return facet version information.
 */

interface IVersionable {
    /// @dev Returns the facet version.
    function facetVersion() external pure returns (string memory);

    /// @dev Returns the facet name.
    function facetName() external pure returns (string memory);
}

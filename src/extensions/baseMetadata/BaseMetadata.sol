// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IBaseMetadata} from "./IBaseMetadata.sol";
import {BaseMetadataInternal} from "./BaseMetadataInternal.sol";

/**
 *  @title   Base Metadata
 *  @notice  Base Metadata extension is used to have a base URI for all tokens on a contract
 */
abstract contract BaseMetadata is IBaseMetadata, BaseMetadataInternal {
    /**
     *  @dev Returns whether base uri can be set in the given execution context.
     *       Needs to be overridden by any contract inheriting BaseMetadata
     */
    function _canSetBaseURI() internal view virtual returns (bool);
}

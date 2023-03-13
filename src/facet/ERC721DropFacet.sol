// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721Drop, IERC721Drop} from "src/extensions/ERC721Drop/ERC721Drop.sol";
import {ERC721DropStorage} from "src/extensions/ERC721Drop/ERC721DropStorage.sol";

import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

contract ERC721DropFacet is ERC721Drop {}

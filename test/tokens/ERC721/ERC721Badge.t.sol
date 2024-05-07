// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {ERC721BadgeMock} from "src/tokens/ERC721/ERC721BadgeMock.sol";
import {ERC721LazyMint} from "src/tokens/ERC721/ERC721Badge.sol";

uint256 constant MAX_INT = 2 ** 256 - 1;

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    address globals = address(0x12);

    ERC721BadgeMock erc721Badge;

    uint16 tenPercentBPS = 1000;
    bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
    bytes32 constant MINTER_ROLE = bytes32(uint256(1));

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";

    function setUp() public {
        vm.prank(creator);
        erc721Badge = new ERC721BadgeMock("Name", "Symbol", creator, uint16(tenPercentBPS), "");

        afterSetup();
    }

    // can override this function to perform further setup tasks
    function afterSetup() public virtual {}
}

contract ERC721Badge_initialise is Setup {
    function test_initialized() public {
        assertEq("Name", erc721Badge.name());
        assertEq("Symbol", erc721Badge.symbol());
        assertEq(creator, erc721Badge.owner());
    }
}

contract ERC721Badge__lazyMint is Setup {
    function test_can_lazy_mint_all_tokens() public {
        vm.prank(creator);
        erc721Badge.lazyMint(MAX_INT, baseURI, "");

        assertEq(baseURI, erc721Badge.tokenURI(0));
        assertEq(baseURI, erc721Badge.tokenURI(MAX_INT - 1));
    }

    function test_reverts_when_all_tokens_lazy_minted() public {
        vm.prank(creator);
        erc721Badge.lazyMint(MAX_INT, baseURI, "");

        vm.expectRevert();
        vm.prank(creator);
        erc721Badge.lazyMint(1, baseURI, "");
    }
}

contract ERC721Badge__setBaseURI is Setup {
    string differentBaseURI = "some other url";

    function afterSetup() public override {
        vm.prank(creator);
        erc721Badge.lazyMint(MAX_INT, baseURI, "");
    }

    function test_set_base_uri() public {
        vm.prank(creator);
        erc721Badge.setBaseURI(0, differentBaseURI);

        assertEq(differentBaseURI, erc721Badge.tokenURI(0));
        assertEq(differentBaseURI, erc721Badge.tokenURI(MAX_INT - 1));
    }

    function test_reverts_when_access_is_invalid() public {
        vm.expectRevert(ERC721LazyMint.ERC721LazyMint_notAuthorized.selector);
        vm.prank(other);
        erc721Badge.setBaseURI(0, differentBaseURI);
    }
}

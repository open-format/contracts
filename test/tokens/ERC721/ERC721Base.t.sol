// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {ERC721BaseMock} from "../../../src/tokens/ERC721/ERC721BaseMock.sol";

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    ERC721BaseMock erc721Base;

    uint16 tenPercentBPS = 1000;

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";
    string tokenURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/metadata.json";

    function setUp() public {
        vm.prank(creator);
        erc721Base = new ERC721BaseMock(
          "Name",
          "Symbol",
          creator,
          uint16(tenPercentBPS)
        );

        setUpAfter();
    }

    // can override this function to perform further setup tasks
    function setUpAfter() public virtual {}
}

contract ERC721Base__initialize is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(creator, tokenURI);
    }

    function test_can_only_be_run_once() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        erc721Base.initialize("Name", "Symbol", creator, uint16(tenPercentBPS));
    }
}

contract ERC721Base__royaltyInfo is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(creator, tokenURI);
    }

    function test_gets_reciever_and_amount() public {
        (address reciever, uint256 amount) = erc721Base.royaltyInfo(0, 1 ether);
        assertEq(reciever, creator);
        assertEq(amount, 0.1 ether);
    }

    function test_supports_ERC2981_interface() public {
        assertTrue(erc721Base.supportsInterface(type(IERC2981).interfaceId));
    }
}

contract ERC721Base__mintTo is Setup {
    function test_mints_to_address() public {
        vm.prank(creator);
        erc721Base.mintTo(other, tokenURI);

        assertEq(other, erc721Base.ownerOf(0));
    }
}

contract ERC721Base__batchMintTo is Setup {
    function test_mints_multiple_to_address() public {
        vm.prank(creator);
        erc721Base.batchMintTo(other, 3, baseURI);

        assertEq(other, erc721Base.ownerOf(0));
        assertEq(other, erc721Base.ownerOf(1));
        assertEq(other, erc721Base.ownerOf(2));
    }

    function test_appends_token_id_to_baseURI() public {
        vm.prank(creator);
        erc721Base.batchMintTo(other, 3, baseURI);

        assertEq(erc721Base.tokenURI(0), string.concat(baseURI, "0"));
        assertEq(erc721Base.tokenURI(1), string.concat(baseURI, "1"));
        assertEq(erc721Base.tokenURI(2), string.concat(baseURI, "2"));
    }

    function test_can_be_mixed_with_mintTo() public {
        vm.prank(creator);
        erc721Base.mintTo(other, tokenURI);

        vm.prank(creator);
        erc721Base.batchMintTo(other, 2, baseURI);

        assertEq(erc721Base.tokenURI(0), tokenURI);
        assertEq(erc721Base.tokenURI(1), string.concat(baseURI, "1"));
        assertEq(erc721Base.tokenURI(2), string.concat(baseURI, "2"));
    }
}

contract ERC721Base__burn is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(other, tokenURI);
    }

    function test_burns_token() public {
        vm.prank(other);
        erc721Base.burn(0);

        vm.expectRevert();
        erc721Base.ownerOf(0);
    }
}

contract ERC721Base__setContractURI is Setup {
    function test_sets_contract_uri() public {
        vm.prank(creator);
        erc721Base.setContractURI(tokenURI);

        assertEq(tokenURI, erc721Base.contractURI());
    }

    function test_only_owner_can_set_contract_uri() public {
        vm.prank(other);
        vm.expectRevert();
        erc721Base.setContractURI(tokenURI);
    }
}

contract ERC721Base__transferFrom is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(other, tokenURI);
    }

    function test_can_transfer_token() public {
        vm.prank(other);
        erc721Base.transferFrom(other, creator, 0);

        assertEq(erc721Base.ownerOf(0), creator);
    }

    function test_can_safe_transfer_token() public {
        vm.prank(other);
        erc721Base.safeTransferFrom(other, creator, 0);

        assertEq(erc721Base.ownerOf(0), creator);
    }
}

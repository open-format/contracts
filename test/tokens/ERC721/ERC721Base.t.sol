// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ERC721BaseMock} from "../../../src/tokens/ERC721/ERC721BaseMock.sol";

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    ERC721BaseMock erc721Base;

    uint16 tenPercentBPS = 1000;

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
        erc721Base.mintTo(creator);
    }

    function test_can_only_be_run_once() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        erc721Base.initialize("Name", "Symbol", creator, uint16(tenPercentBPS));
    }
}

contract ERC721Base__royaltyInfo is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(creator);
    }

    function test_gets_reciever_and_amount() public {
        (address reciever, uint256 amount) = erc721Base.royaltyInfo(0, 1 ether);
        assertEq(reciever, creator);
        assertEq(amount, 0.1 ether);
    }
}

contract ERC721Base__mintTo is Setup {
    function test_mints_to_address() public {
        vm.prank(creator);
        erc721Base.mintTo(other);

        assertEq(other, erc721Base.ownerOf(0));
    }
}

contract ERC721Base__batchMintTo is Setup {
    function test_mints_multiple_to_address() public {
        vm.prank(creator);
        erc721Base.batchMintTo(other, 3);

        assertEq(other, erc721Base.ownerOf(0));
        assertEq(other, erc721Base.ownerOf(1));
        assertEq(other, erc721Base.ownerOf(2));
    }
}

contract ERC721Base__burn is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(other);
    }

    function test_burns_token() public {
        vm.prank(other);
        erc721Base.burn(0);

        vm.expectRevert();
        erc721Base.ownerOf(0);
    }
}

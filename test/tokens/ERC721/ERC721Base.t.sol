// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {ERC721BaseMock, ERC721Base} from "../../../src/tokens/ERC721/ERC721BaseMock.sol";

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    address globals = address(0x12);

    ERC721BaseMock erc721Base;

    uint16 tenPercentBPS = 1000;
    bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
    bytes32 constant MINTER_ROLE = bytes32(uint256(1));

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";
    string tokenURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/metadata.json";

    function setUp() public {
        vm.prank(creator);
        erc721Base = new ERC721BaseMock(
          "Name",
          "Symbol",
          creator,
          uint16(tenPercentBPS),
          ""
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
        erc721Base.initialize(creator, "Name", "Symbol", creator, uint16(tenPercentBPS), "");
    }

    function test_sets_minter_role_and_global_when_passed_encoded_data() public {
        bytes memory data = abi.encode(other, globals);
        erc721Base = new ERC721BaseMock(
          "Name",
          "Symbol",
          creator,
          uint16(tenPercentBPS),
          data
        );

        assertTrue(erc721Base.hasRole(MINTER_ROLE, other));
        assertEq(erc721Base._globals(), globals);
    }

    function test_does_not_grant_minter_role_when_passed_encoded_zero_address() public {
        bytes memory data = abi.encode(address(0), globals);
        erc721Base = new ERC721BaseMock(
          "Name",
          "Symbol",
          creator,
          uint16(tenPercentBPS),
          data
        );

        assertFalse(erc721Base.hasRole(MINTER_ROLE, address(0)));
    }

    function test_minter_role_and_globals_are_set_with_extra_data() public {
        bytes memory data = abi.encode(other, globals, 12356789);

        erc721Base = new ERC721BaseMock(
          "Name",
          "Symbol",
          creator,
          uint16(tenPercentBPS),
          data
        );

        assertTrue(erc721Base.hasRole(MINTER_ROLE, other));
        assertEq(erc721Base._globals(), globals);
    }
}

contract ERC721Base__royaltyInfo is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.mintTo(creator, tokenURI);
    }

    function test_gets_receiver_and_amount() public {
        (address receiver, uint256 amount) = erc721Base.royaltyInfo(0, 1 ether);
        assertEq(receiver, creator);
        assertEq(amount, 0.1 ether);
    }

    function test_supports_ERC2981_interface() public {
        assertTrue(erc721Base.supportsInterface(type(IERC2981).interfaceId));
    }

    function test_returns_token_specific_royalty_info() public {
        vm.prank(creator);

        uint16 fivePercentBPS = 500;
        erc721Base.setRoyaltyInfoForToken(0, other, fivePercentBPS);

        (address receiver, uint256 amount) = erc721Base.royaltyInfo(0, 1 ether);
        assertEq(receiver, other);
        assertEq(amount, 0.05 ether);
    }
}

contract ERC721Base__mintTo is Setup {
    function test_mints_to_address() public {
        vm.prank(creator);
        erc721Base.mintTo(other, tokenURI);

        assertEq(other, erc721Base.ownerOf(0));
    }

    function test_reverts_if_not_authorised() public {
        vm.expectRevert(ERC721Base.ERC721Base_notAuthorized.selector);
        vm.prank(other);
        erc721Base.mintTo(other, tokenURI);
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

    function test_reverts_if_not_authorised() public {
        vm.expectRevert(ERC721Base.ERC721Base_notAuthorized.selector);
        vm.prank(other);
        erc721Base.batchMintTo(other, 3, baseURI);
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

contract ERC721Base__owner is Setup {
    function test_owner() public {
        vm.prank(creator);
        assertEq(creator, erc721Base.owner());
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

contract ERC721Base__multicall is Setup {
    function setUpAfter() public override {
        vm.prank(creator);
        erc721Base.batchMintTo(creator, 2, tokenURI);
    }

    function test_can_perfom_multiple_calls_in_one_transaction() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(erc721Base.transferFrom, (creator, other, 0));
        calls[1] = abi.encodeCall(erc721Base.transferFrom, (creator, other, 1));

        vm.prank(creator);
        erc721Base.multicall(calls);

        assertEq(erc721Base.ownerOf(0), other);
        assertEq(erc721Base.ownerOf(1), other);
    }
}

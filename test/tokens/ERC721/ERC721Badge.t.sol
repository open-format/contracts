// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {ERC721BadgeMock} from "src/tokens/ERC721/ERC721BadgeMock.sol";
import {ERC721Badge} from "src/tokens/ERC721/ERC721Badge.sol";
import {IBatchMintMetadata} from "src/extensions/batchMintMetadata/IBatchMintMetadata.sol";

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
        bytes memory data = abi.encode(address(0), address(0), baseURI);
        erc721Badge = new ERC721BadgeMock("Name", "Symbol", creator, uint16(tenPercentBPS), data);

        afterSetup();
    }

    // can override this function to perform further setup tasks
    function afterSetup() public virtual {}
}

contract ERC721Badge_initialise is Setup {
    function test_initialise_correctly() public {
        assertEq("Name", erc721Badge.name());
        assertEq("Symbol", erc721Badge.symbol());
        assertEq(creator, erc721Badge.owner());
        assertEq(baseURI, erc721Badge.tokenURI(0));
    }

    function test_initialise_with_empty_string() public {
        vm.prank(creator);

        // global and minter address but baseTokenURI is an empty string
        bytes memory data = abi.encode(address(0), address(0), "");

        // initialises
        ERC721Badge emptyString = new ERC721BadgeMock("Name", "Symbol", creator, uint16(tenPercentBPS), data);

        // but tokenURI reverts
        vm.expectRevert(IBatchMintMetadata.BatchMintMetadata_invalidTokenId.selector);
        emptyString.tokenURI(0);

        // mintTo will revert also
        vm.expectRevert();
        emptyString.mintTo(creator);
    }

    function test_should_revert_when_initialised_without_base_token_URI() public {
        vm.prank(creator);
        // global and minter address but no baseTokenURI in data
        bytes memory data = abi.encode(address(0), address(0));
        vm.expectRevert();
        new ERC721BadgeMock("Name", "Symbol", creator, uint16(tenPercentBPS), data);
    }
}

contract ERC721Badge__setBaseURI is Setup {
    string differentBaseURI = "some other url";

    function test_set_base_uri_for_all_tokens() public {
        vm.prank(creator);
        erc721Badge.setBaseURI(differentBaseURI);

        assertEq(differentBaseURI, erc721Badge.tokenURI(0));
        assertEq(differentBaseURI, erc721Badge.tokenURI(MAX_INT - 1));
    }

    function test_set_base_uri_when_not_set_on_initialise() public {
        // global and minter address but baseTokenURI is an empty string
        bytes memory data = abi.encode(address(0), address(0), "");
        vm.prank(creator);
        ERC721Badge erc721BadgeNoBaseURI = new ERC721BadgeMock("Name", "Symbol", creator, uint16(tenPercentBPS), data);

        vm.prank(creator);
        erc721BadgeNoBaseURI.setBaseURI(baseURI);

        assertEq(baseURI, erc721Badge.tokenURI(0));
        assertEq(baseURI, erc721Badge.tokenURI(MAX_INT - 1));
    }

    function test_reverts_when_access_is_invalid() public {
        vm.expectRevert(ERC721Badge.ERC721Badge_notAuthorized.selector);
        vm.prank(other);
        erc721Badge.setBaseURI(differentBaseURI);
    }
}

// Copied from lazymint

contract ERC721Badge__royaltyInfo is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721Badge.mintTo(creator);
    }

    function test_gets_receiver_and_amount() public {
        (address receiver, uint256 amount) = erc721Badge.royaltyInfo(0, 1 ether);
        assertEq(receiver, creator);
        assertEq(amount, 0.1 ether);
    }

    function test_supports_ERC2981_interface() public {
        assertTrue(erc721Badge.supportsInterface(type(IERC2981).interfaceId));
    }

    function test_returns_token_specific_royalty_info() public {
        uint16 fivePercentBPS = 500;

        vm.prank(creator);
        erc721Badge.setRoyaltyInfoForToken(0, other, fivePercentBPS);

        (address receiver, uint256 amount) = erc721Badge.royaltyInfo(0, 1 ether);
        assertEq(receiver, other);
        assertEq(amount, 0.05 ether);
    }
}

contract ERC721Badge__grantRole is Setup {
    function test_can_grant_admin_role() public {
        vm.prank(creator);
        erc721Badge.grantRole(ADMIN_ROLE, other);

        vm.prank(other);
        erc721Badge.mintTo(other);
        assertEq(erc721Badge.ownerOf(0), other);
    }

    function test_can_grant_minter_role() public {
        vm.prank(creator);
        erc721Badge.grantRole(MINTER_ROLE, other);

        vm.prank(other);
        erc721Badge.mintTo(other);
        assertEq(erc721Badge.ownerOf(0), other);
    }
}

contract ERC721Badge__revokeRole is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721Badge.grantRole(MINTER_ROLE, other);
    }

    function test_can_revoke_role() public {
        vm.prank(creator);
        erc721Badge.revokeRole(MINTER_ROLE, other);

        vm.expectRevert(ERC721Badge.ERC721Badge_notAuthorized.selector);
        vm.prank(other);
        erc721Badge.mintTo(other);
    }

    function test_reverts_if_not_admin() public {
        vm.expectRevert();
        vm.prank(other);
        erc721Badge.revokeRole(MINTER_ROLE, other);
    }
}

contract ERC721Badge__mintTo is Setup {
    function test_mints_to_address() public {
        vm.prank(creator);
        erc721Badge.mintTo(other);

        assertEq(other, erc721Badge.ownerOf(0));
    }

    function test_reverts_if_not_authorised() public {
        vm.expectRevert(ERC721Badge.ERC721Badge_notAuthorized.selector);
        vm.prank(other);
        erc721Badge.mintTo(other);
    }
}

contract ERC721Badge__batchMintTo is Setup {
    function test_mints_multiple_to_address() public {
        vm.prank(creator);
        erc721Badge.batchMintTo(other, 3);

        assertEq(other, erc721Badge.ownerOf(0));
        assertEq(other, erc721Badge.ownerOf(1));
        assertEq(other, erc721Badge.ownerOf(2));
    }

    function test_can_be_mixed_with_mintTo() public {
        vm.prank(creator);
        erc721Badge.mintTo(other);

        vm.prank(creator);
        erc721Badge.batchMintTo(other, 2);

        assertEq(erc721Badge.tokenURI(0), baseURI);
        assertEq(erc721Badge.tokenURI(1), baseURI);
        assertEq(erc721Badge.tokenURI(2), baseURI);
    }

    function test_reverts_if_not_authorised() public {
        vm.expectRevert(ERC721Badge.ERC721Badge_notAuthorized.selector);
        vm.prank(other);
        erc721Badge.batchMintTo(other, 2);
    }
}

contract ERC721Badge__burn is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721Badge.mintTo(other);
    }

    function test_burns_token() public {
        vm.prank(other);
        erc721Badge.burn(0);

        vm.expectRevert();
        erc721Badge.ownerOf(0);
    }
}

contract ERC721Badge__setContractURI is Setup {
    function test_sets_contract_uri() public {
        vm.prank(creator);
        erc721Badge.setContractURI(baseURI);

        assertEq(baseURI, erc721Badge.contractURI());
    }

    function test_only_owner_can_set_contract_uri() public {
        vm.prank(other);
        vm.expectRevert();
        erc721Badge.setContractURI(baseURI);
    }
}

contract ERC721Badge__owner is Setup {
    function test_owner() public {
        vm.prank(creator);
        assertEq(creator, erc721Badge.owner());
    }
}

contract ERC721Badge__transferFrom is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721Badge.mintTo(other);
    }

    function test_can_transfer_token() public {
        vm.prank(other);
        erc721Badge.transferFrom(other, creator, 0);

        assertEq(erc721Badge.ownerOf(0), creator);
    }

    function test_can_safe_transfer_token() public {
        vm.prank(other);
        erc721Badge.safeTransferFrom(other, creator, 0);

        assertEq(erc721Badge.ownerOf(0), creator);
    }
}

contract ERC721Badge__multicall is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721Badge.batchMintTo(creator, 2);
    }

    function test_can_perform_multiple_calls_in_one_transaction() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(erc721Badge.transferFrom, (creator, other, 0));
        calls[1] = abi.encodeCall(erc721Badge.transferFrom, (creator, other, 1));

        vm.prank(creator);
        erc721Badge.multicall(calls);

        assertEq(erc721Badge.ownerOf(0), other);
        assertEq(erc721Badge.ownerOf(1), other);
    }
}

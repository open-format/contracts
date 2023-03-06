// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {ERC721LazyMintMock, ERC721LazyMint} from "src/tokens/ERC721/ERC721LazyMintMock.sol";
import {ILazyMint} from "@extensions/lazyMint/LazyMint.sol";

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    ERC721LazyMintMock erc721LazyMint;

    uint16 tenPercentBPS = 1000;
    bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
    bytes32 constant MINTER_ROLE = bytes32(uint256(1));

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";

    function setUp() public {
        vm.prank(creator);
        erc721LazyMint = new ERC721LazyMintMock(
          "Name",
          "Symbol",
          creator,
          uint16(tenPercentBPS)
        );

        afterSetup();
    }

    // can override this function to perform further setup tasks
    function afterSetup() public virtual {}
}

contract ERC721LazyMint__initialize is Setup {
    function test_can_only_be_run_once() public {
        vm.expectRevert("ERC721A__Initializable: contract is already initialized");
        erc721LazyMint.initialize(creator, "Name", "Symbol", creator, uint16(tenPercentBPS));
    }
}

contract ERC721LazyMint__royaltyInfo is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(1, baseURI, "");

        vm.prank(creator);
        erc721LazyMint.mintTo(creator);
    }

    function test_gets_receiver_and_amount() public {
        (address receiver, uint256 amount) = erc721LazyMint.royaltyInfo(0, 1 ether);
        assertEq(receiver, creator);
        assertEq(amount, 0.1 ether);
    }

    function test_supports_ERC2981_interface() public {
        assertTrue(erc721LazyMint.supportsInterface(type(IERC2981).interfaceId));
    }

    function test_returns_token_specific_royalty_info() public {
        uint16 fivePercentBPS = 500;

        vm.prank(creator);
        erc721LazyMint.setRoyaltyInfoForToken(0, other, fivePercentBPS);

        (address receiver, uint256 amount) = erc721LazyMint.royaltyInfo(0, 1 ether);
        assertEq(receiver, other);
        assertEq(amount, 0.05 ether);
    }
}

contract ERC721LazyMint__lazyMint is Setup {
    function test_can_lazy_mint() public {
        vm.prank(creator);
        erc721LazyMint.lazyMint(2, baseURI, "");

        assertEq(baseURI, erc721LazyMint.tokenURI(0));
        assertEq(baseURI, erc721LazyMint.tokenURI(1));
    }

    function test_reverts_when_access_is_invalid() public {
        vm.expectRevert(ILazyMint.Error_not_authorized_to_lazy_mint.selector);
        vm.prank(other);
        erc721LazyMint.lazyMint(2, baseURI, "");
    }
}

contract ERC721LazyMint__grantRole is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(1, baseURI, "");
    }

    function test_can_grant_admin_role() public {
        vm.prank(creator);
        erc721LazyMint.grantRole(ADMIN_ROLE, other);

        vm.prank(other);
        erc721LazyMint.mintTo(other);
        assertEq(erc721LazyMint.ownerOf(0), other);
    }

    function test_can_grant_minter_role() public {
        vm.prank(creator);
        erc721LazyMint.grantRole(MINTER_ROLE, other);

        vm.prank(other);
        erc721LazyMint.mintTo(other);
        assertEq(erc721LazyMint.ownerOf(0), other);
    }
}

contract ERC721LazyMint__revokeRole is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(1, baseURI, "");

        vm.prank(creator);
        erc721LazyMint.grantRole(MINTER_ROLE, other);
    }

    function test_can_revoke_role() public {
        vm.prank(creator);
        erc721LazyMint.revokeRole(MINTER_ROLE, other);

        vm.expectRevert("Not authorized to mint.");
        vm.prank(other);
        erc721LazyMint.mintTo(other);
    }

    function test_reverts_if_not_admin() public {
        vm.expectRevert();
        vm.prank(other);
        erc721LazyMint.revokeRole(MINTER_ROLE, other);
    }
}

contract ERC721LazyMint__mintTo is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(1, baseURI, "");
    }

    function test_mints_to_address() public {
        vm.prank(creator);
        erc721LazyMint.mintTo(other);

        assertEq(other, erc721LazyMint.ownerOf(0));
    }
}

contract ERC721LazyMint__batchMintTo is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(3, baseURI, "");
    }

    function test_mints_multiple_to_address() public {
        vm.prank(creator);
        erc721LazyMint.batchMintTo(other, 3);

        assertEq(other, erc721LazyMint.ownerOf(0));
        assertEq(other, erc721LazyMint.ownerOf(1));
        assertEq(other, erc721LazyMint.ownerOf(2));
    }

    function test_can_be_mixed_with_mintTo() public {
        vm.prank(creator);
        erc721LazyMint.mintTo(other);

        vm.prank(creator);
        erc721LazyMint.batchMintTo(other, 2);

        assertEq(erc721LazyMint.tokenURI(0), baseURI);
        assertEq(erc721LazyMint.tokenURI(1), baseURI);
        assertEq(erc721LazyMint.tokenURI(2), baseURI);
    }
}

contract ERC721LazyMint__burn is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(1, baseURI, "");
        vm.prank(creator);
        erc721LazyMint.mintTo(other);
    }

    function test_burns_token() public {
        vm.prank(other);
        erc721LazyMint.burn(0);

        vm.expectRevert();
        erc721LazyMint.ownerOf(0);
    }
}

contract ERC721LazyMint__setContractURI is Setup {
    function test_sets_contract_uri() public {
        vm.prank(creator);
        erc721LazyMint.setContractURI(baseURI);

        assertEq(baseURI, erc721LazyMint.contractURI());
    }

    function test_only_owner_can_set_contract_uri() public {
        vm.prank(other);
        vm.expectRevert();
        erc721LazyMint.setContractURI(baseURI);
    }
}

contract ERC721LazyMint__transferFrom is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(1, baseURI, "");
        vm.prank(creator);
        erc721LazyMint.mintTo(other);
    }

    function test_can_transfer_token() public {
        vm.prank(other);
        erc721LazyMint.transferFrom(other, creator, 0);

        assertEq(erc721LazyMint.ownerOf(0), creator);
    }

    function test_can_safe_transfer_token() public {
        vm.prank(other);
        erc721LazyMint.safeTransferFrom(other, creator, 0);

        assertEq(erc721LazyMint.ownerOf(0), creator);
    }
}

contract ERC721LazyMint__multicall is Setup {
    function afterSetup() public override {
        vm.prank(creator);
        erc721LazyMint.lazyMint(2, baseURI, "");
        vm.prank(creator);
        erc721LazyMint.batchMintTo(creator, 2);
    }

    function test_can_perform_multiple_calls_in_one_transaction() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(erc721LazyMint.transferFrom, (creator, other, 0));
        calls[1] = abi.encodeCall(erc721LazyMint.transferFrom, (creator, other, 1));

        vm.prank(creator);
        erc721LazyMint.multicall(calls);

        assertEq(erc721LazyMint.ownerOf(0), other);
        assertEq(erc721LazyMint.ownerOf(1), other);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {LazyMintMock, ILazyMint} from "src/extensions/lazyMint/LazyMintMock.sol";

contract Setup is Test {
    address minter;
    address other;
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";
    LazyMintMock lazyMint;

    function setUp() public {
        minter = address(0x10);
        other = address(0x11);

        lazyMint = new LazyMintMock(minter);

        _afterSetup();
    }

    function _afterSetup() internal virtual {}
}

contract LazyMint__lazyMint is Setup {
    event TokensLazyMinted(uint256 indexed startTokenId, uint256 endTokenId, string baseURI, bytes encryptedBaseURI);

    function test_can_lazy_mint() public {
        vm.prank(minter);
        lazyMint.lazyMint(1, baseURI, "");

        assertEq(lazyMint.getBaseURI(0), baseURI);
    }

    function test_can_lazy_mint_multiple() public {
        vm.prank(minter);
        lazyMint.lazyMint(2, baseURI, "");

        assertEq(lazyMint.getBaseURI(0), baseURI);
        assertEq(lazyMint.getBaseURI(1), baseURI);
    }

    function test_returns_batch_id() public {
        // batchId = startId + amountToMint see extensions/batchMetadata
        // batch 0
        {
            vm.prank(minter);
            uint256 batchId = lazyMint.lazyMint(10, baseURI, "");
            assertEq(batchId, 10);
        }
        // batch 1
        {
            vm.prank(minter);
            uint256 batchId = lazyMint.lazyMint(10, baseURI, "");
            assertEq(batchId, 20);
        }
    }

    function test_emits_TokensLazyMinted_event() public {
        // batch 0
        {
            vm.expectEmit(true, true, true, true);
            emit TokensLazyMinted(0, 0, baseURI, "");

            vm.prank(minter);
            lazyMint.lazyMint(1, baseURI, "");
        }
        // batch 1
        {
            vm.expectEmit(true, true, true, true);
            emit TokensLazyMinted(1, 10, baseURI, "");

            vm.prank(minter);
            lazyMint.lazyMint(10, baseURI, "");
        }
    }

    function test_reverts_when_minter_is_not_authorized() public {
        vm.expectRevert(ILazyMint.LazyMint_notAuthorizedToLazyMint.selector);

        vm.prank(other);
        lazyMint.lazyMint(1, baseURI, "");
    }

    function test_reverts_when_amount_is_zero() public {
        vm.expectRevert(ILazyMint.LazyMint_zeroAmount.selector);

        vm.prank(minter);
        lazyMint.lazyMint(0, baseURI, "");
    }
}

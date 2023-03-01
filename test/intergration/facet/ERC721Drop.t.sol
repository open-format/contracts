// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// The following tests that the settings facet works as intentioned within the open format contracts

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {Factory} from "src/factory/Factory.sol";
import {Globals} from "src/globals/Globals.sol";

import {ERC721LazyMint} from "src/tokens/ERC721/ERC721LazyMint.sol";

import {SettingsFacet} from "src/facet/SettingsFacet.sol";

abstract contract Helpers {
    function prepareSingleFacetCut(
        address cutAddress,
        IDiamondWritableInternal.FacetCutAction cutAction,
        bytes4[] memory selectors
    ) public pure returns (IDiamondWritableInternal.FacetCut[] memory) {
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(cutAddress, cutAction, selectors);
        return cuts;
    }
}

contract Setup is Test, Helpers {
    address appOwner;
    address nftOwner;
    address other;

    uint16 tenPercentBPS = 1000;

    Factory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;

    ERC721LazyMint erc721;

    function setUp() public {
        // assign addresses
        appOwner = address(0x10);
        nftOwner = address(0x11);
        other = address(0x12);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new  Proxy(true);
        appFactory = new Factory(address(appImplementation), address(registry), address(globals));

        settingsFacet = new SettingsFacet();

        // add facet to registry
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = settingsFacet.setApplicationFee.selector;
        selectors[1] = settingsFacet.setAcceptedCurrencies.selector;
        selectors[2] = settingsFacet.applicationFeeInfo.selector;

        registry.diamondCut(
            prepareSingleFacetCut(address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );

        // create app
        vm.prank(appOwner);
        app = Proxy(payable(appFactory.create("SettingsTest")));

        // Note: just deploy a erc721 for testing no need to do factory facet biz yet
        vm.prank(nftOwner);
        erc721 = new ERC721LazyMint("BLAH", "BLAH", nftOwner, 1_000);

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {}
}

/* peace of mind test for access control */

contract ERC721LazyMint_grantRole is Setup {
    bytes32 MINTER_ROLE = bytes32(uint256(1));

    function test_can_grant_minter_role() public {
        vm.prank(nftOwner);
        erc721.grantRole(MINTER_ROLE, other);

        assertTrue(erc721.hasRole(MINTER_ROLE, other));
    }

    function test_reverts_if_others_grant_minter_role() public {
        vm.expectRevert();
        vm.prank(other);
        erc721.grantRole(MINTER_ROLE, other);
    }
}

contract ERC721LazyMint_lazyMint is Setup {
    function test_can_lazy_mint() public {
        vm.prank(nftOwner);
        erc721.lazyMint(3, "ipfs://lalala/", "");

        vm.prank(nftOwner);
        erc721.mintTo(other);

        vm.prank(nftOwner);
        erc721.batchMintTo(other, 2);

        assertEq(erc721.ownerOf(0), other);
        assertEq(erc721.ownerOf(1), other);
        assertEq(erc721.ownerOf(2), other);
    }

    function test_reverts_if_not_lazy_minted() public {
        vm.prank(nftOwner);
        erc721.lazyMint(1, "ipfs://lalala/", "");

        vm.prank(nftOwner);
        erc721.mintTo(other);

        vm.expectRevert("Not enough lazy minted tokens");
        vm.prank(nftOwner);
        erc721.mintTo(other);
    }

    function test_reverts_if_not_lazy_minted_batch() public {
        vm.prank(nftOwner);
        erc721.lazyMint(2, "ipfs://lalala/", "");

        vm.prank(nftOwner);
        erc721.batchMintTo(other, 2);

        vm.expectRevert("Not enough lazy minted tokens");
        vm.prank(nftOwner);
        erc721.batchMintTo(other, 1);
    }
}

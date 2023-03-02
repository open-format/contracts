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
import {ERC721DropFacet, ERC721DropFacetStorage} from "src/facet/ERC721DropFacet/ERC721DropFacet.sol";

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
    ERC721DropFacet dropFacet;

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

        {
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
        }

        {
            dropFacet = new ERC721DropFacet();

            // add facet to registry
            bytes4[] memory selectors = new bytes4[](3);
            selectors[0] = dropFacet.setClaimCondition.selector;
            selectors[1] = dropFacet.getClaimCondition.selector;
            selectors[2] = dropFacet.claim.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(dropFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

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

contract ERC721DropFacet_setClaimCondition is Setup {
    ERC721DropFacetStorage.ClaimCondition testClaimCondition;

    event ClaimConditionUpdated(ERC721DropFacetStorage.ClaimCondition condition, bool resetEligibility);

    function _afterSetUp() internal override {
        testClaimCondition = ERC721DropFacetStorage.ClaimCondition({
            startTimestamp: 0,
            maxClaimableSupply: 10,
            supplyClaimed: 0,
            quantityLimitPerWallet: 1,
            pricePerToken: 0,
            currency: address(0)
        });
    }

    function assertEqClaimCondition(
        ERC721DropFacetStorage.ClaimCondition memory _A,
        ERC721DropFacetStorage.ClaimCondition memory _B
    ) public {
        assertEq(_A.startTimestamp, _B.startTimestamp);
        assertEq(_A.supplyClaimed, _B.supplyClaimed);
        assertEq(_A.maxClaimableSupply, _B.maxClaimableSupply);
        assertEq(_A.quantityLimitPerWallet, _B.quantityLimitPerWallet);
        assertEq(_A.pricePerToken, _B.pricePerToken);
        assertEq(_A.currency, _B.currency);
    }

    function test_can_set_claim_condition() public {
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);

        ERC721DropFacetStorage.ClaimCondition memory claimCondition =
            ERC721DropFacet(address(app)).getClaimCondition(address(erc721));

        assertEqClaimCondition(claimCondition, testClaimCondition);
    }

    function test_only_token_contract_owner_can_set_claim_condition() public {
        vm.expectRevert("must be contract owner");
        vm.prank(other);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);
    }

    function test_update_claim_condition() public {
        // set claim condition
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);

        // create a new claim condition with updated startTimestamp and pricePerToken
        ERC721DropFacetStorage.ClaimCondition memory newClaimCondition = testClaimCondition;
        newClaimCondition.startTimestamp = 1000;
        newClaimCondition.pricePerToken = 1 ether;

        // update
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), newClaimCondition, true);

        ERC721DropFacetStorage.ClaimCondition memory claimCondition =
            ERC721DropFacet(address(app)).getClaimCondition(address(erc721));
        assertEqClaimCondition(claimCondition, newClaimCondition);
    }

    function test_emits_ClaimConditionUpdated() public {
        vm.expectEmit(true, true, true, true);
        emit ClaimConditionUpdated(testClaimCondition, false);
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);
    }
}

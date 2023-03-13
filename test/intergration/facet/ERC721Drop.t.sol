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
import {ERC721DropFacet, ERC721DropStorage} from "src/facet/ERC721DropFacet.sol";

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
    address socialConscienceLayer;

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
        socialConscienceLayer = address(0x13);

        vm.deal(other, 1.1 ether);

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
        app = Proxy(payable(appFactory.create("App Name")));

        // Add NATIVE_TOKEN to accepted currencies
        {
            address[] memory currencies = new address[](1);
            currencies[0] = address(0);
            bool[] memory approvals = new bool[](1);
            approvals[0] = true;
            vm.prank(appOwner);
            SettingsFacet(address(app)).setAcceptedCurrencies(currencies, approvals);
        }

        // Note: just deploy a erc721 for testing no need to do factory facet biz yet
        vm.prank(nftOwner);
        erc721 = new ERC721LazyMint(true);
        erc721.initialize(nftOwner, "name", "symbol", nftOwner, 1_000);

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

contract ERC721LazyMint_royaltyInfo is Setup {
    function test_can_lazy_mint() public {
        (address recipient, uint256 amount) = erc721.royaltyInfo(0, 10);

        assertEq(recipient, nftOwner);
        assertEq(amount, 1);
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

    function test_lazy_minted_tokens_have_a_tokenURI() public {
        vm.prank(nftOwner);
        erc721.lazyMint(1, "ipfs://1", "");
        assertEq(erc721.tokenURI(0), "ipfs://1");
    }

    function test_can_lazy_mint_batches() public {
        vm.prank(nftOwner);
        erc721.lazyMint(1, "ipfs://1", "");
        vm.prank(nftOwner);
        erc721.lazyMint(1, "ipfs://2", "");

        assertEq(erc721.tokenURI(0), "ipfs://1");
        assertEq(erc721.tokenURI(1), "ipfs://2");
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
    ERC721DropStorage.ClaimCondition testClaimCondition;

    event ClaimConditionUpdated(ERC721DropStorage.ClaimCondition condition, bool resetEligibility);

    function _afterSetUp() internal override {
        testClaimCondition = ERC721DropStorage.ClaimCondition({
            startTimestamp: 0,
            maxClaimableSupply: 10,
            supplyClaimed: 0,
            quantityLimitPerWallet: 1,
            pricePerToken: 0,
            currency: address(0)
        });
    }

    function assertEqClaimCondition(
        ERC721DropStorage.ClaimCondition memory _A,
        ERC721DropStorage.ClaimCondition memory _B
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

        ERC721DropStorage.ClaimCondition memory claimCondition =
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
        ERC721DropStorage.ClaimCondition memory newClaimCondition = testClaimCondition;
        newClaimCondition.startTimestamp = 1000;
        newClaimCondition.pricePerToken = 1 ether;

        // update
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), newClaimCondition, true);

        ERC721DropStorage.ClaimCondition memory claimCondition =
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

contract ERC721DropFacet_claim is Setup {
    bytes32 MINTER_ROLE = bytes32(uint256(1));
    ERC721DropStorage.ClaimCondition testClaimCondition;

    event TokensClaimed(address tokenContract, address claimer, address receiver, uint256 quantityClaimed);

    function _afterSetUp() internal override {
        testClaimCondition = ERC721DropStorage.ClaimCondition({
            startTimestamp: 0,
            maxClaimableSupply: 10,
            supplyClaimed: 0,
            quantityLimitPerWallet: 2,
            pricePerToken: 0,
            currency: address(0)
        });

        vm.prank(nftOwner);
        erc721.lazyMint(100, "ipfs://lalala/", "");

        vm.prank(nftOwner);
        erc721.grantRole(MINTER_ROLE, address(app));

        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);
    }

    function test_can_claim_a_token() public {
        vm.prank(other);
        ERC721DropFacet(address(app)).claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc721.ownerOf(0), other);
    }

    function test_can_batch_claim_a_token() public {
        vm.prank(other);
        ERC721DropFacet(address(app)).claim(
            address(erc721), other, 2, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc721.ownerOf(0), other);
        assertEq(erc721.ownerOf(1), other);
    }

    function test_pays_price_to_recipient_with_native_token() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);

        // make claim with ether
        vm.prank(other);
        ERC721DropFacet(address(app)).claim{value: 1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 1 ether);
    }

    function test_pays_application_fee_with_native_token() public {
        // set application fee
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);

        // make claim with ether
        vm.prank(other);
        ERC721DropFacet(address(app)).claim{value: 1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 0.9 ether);
        assertEq(appOwner.balance, 0.1 ether);
    }

    function test_pays_platform_fee_with_native_token() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);

        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        // make claim with ether
        vm.prank(other);
        ERC721DropFacet(address(app)).claim{value: 1.1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 1 ether);
        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_pays_platform_and_application_fee_with_native_token() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721DropFacet(address(app)).setClaimCondition(address(erc721), testClaimCondition, false);

        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        // set application fee
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        // make claim with ether
        vm.prank(other);
        ERC721DropFacet(address(app)).claim{value: 1.1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 0.9 ether);
        assertEq(appOwner.balance, 0.1 ether);
        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_reverts_when_quantity_per_wallet_limit_exceeded() public {
        vm.prank(other);
        ERC721DropFacet(address(app)).claim(
            address(erc721), other, 2, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        // TODO: replace expectRevert() with vm.expectRevert("!Qty") currently causing compiler error.
        vm.expectRevert();
        vm.prank(other);
        ERC721DropFacet(address(app)).claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );
    }

    function test_reverts_when_app_not_approved_minter() public {
        vm.prank(nftOwner);
        erc721.revokeRole(MINTER_ROLE, address(app));

        vm.expectRevert("Not authorized to mint.");
        vm.prank(other);
        ERC721DropFacet(address(app)).claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );
    }
}

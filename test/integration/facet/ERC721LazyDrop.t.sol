// SPDX-License-Identifier: BUSL-1.1
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
import {AppFactory} from "src/factories/App.sol";
import {Globals} from "src/globals/Globals.sol";

import {ERC20BaseMock} from "src/tokens/ERC20/ERC20BaseMock.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {ERC721LazyMint} from "src/tokens/ERC721/ERC721LazyMint.sol";

import {ERC721LazyDropFacet, ERC721LazyDropStorage} from "src/facet/ERC721LazyDropFacet.sol";
import {SettingsFacet} from "src/facet/SettingsFacet.sol";

import {IERC721LazyDrop} from "src/extensions/ERC721LazyDrop/ERC721LazyDrop.sol";

abstract contract Helpers is Test {
    function prepareSingleFacetCut(
        address cutAddress,
        IDiamondWritableInternal.FacetCutAction cutAction,
        bytes4[] memory selectors
    ) public pure returns (IDiamondWritableInternal.FacetCut[] memory) {
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(cutAddress, cutAction, selectors);
        return cuts;
    }

    function assertEqClaimCondition(
        ERC721LazyDropStorage.ClaimCondition memory _A,
        ERC721LazyDropStorage.ClaimCondition memory _B
    ) public {
        assertEq(_A.startTimestamp, _B.startTimestamp);
        assertEq(_A.endTimestamp, _B.endTimestamp);
        assertEq(_A.supplyClaimed, _B.supplyClaimed);
        assertEq(_A.maxClaimableSupply, _B.maxClaimableSupply);
        assertEq(_A.quantityLimitPerWallet, _B.quantityLimitPerWallet);
        assertEq(_A.pricePerToken, _B.pricePerToken);
        assertEq(_A.currency, _B.currency);
    }
}

contract Setup is Test, Helpers {
    address appOwner;
    address nftOwner;
    address other;
    address socialConscienceLayer;

    uint16 tenPercentBPS = 1000;

    AppFactory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;
    ERC721LazyDropFacet dropFacet;

    ERC721LazyMint erc721;
    ERC20BaseMock erc20;
    ERC20Base erc20Implementation;

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
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        erc20Implementation = new ERC20Base();

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
            dropFacet = new ERC721LazyDropFacet();

            // add facet to registry
            bytes4[] memory selectors = new bytes4[](5);
            selectors[0] = dropFacet.ERC721LazyDrop_setClaimCondition.selector;
            selectors[1] = dropFacet.ERC721LazyDrop_getClaimCondition.selector;
            selectors[2] = dropFacet.ERC721LazyDrop_claim.selector;
            selectors[3] = dropFacet.ERC721LazyDrop_verifyClaim.selector;
            selectors[4] = dropFacet.ERC721LazyDrop_removeClaimCondition.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(dropFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        // create erc20 token
        erc20 = new ERC20BaseMock("name", "symbol", 18, 100 ether);
        erc20.transfer(other, 1 ether);

        // create app
        vm.prank(appOwner);
        app = Proxy(payable(appFactory.create("ERC721LazyMintTest", appOwner)));
        // Add NATIVE_TOKEN and ERC20 to accepted currencies
        {
            address[] memory currencies = new address[](2);
            currencies[0] = address(0);
            currencies[1] = address(erc20);
            bool[] memory approvals = new bool[](2);
            approvals[0] = true;
            approvals[1] = true;
            vm.prank(appOwner);
            SettingsFacet(address(app)).setAcceptedCurrencies(currencies, approvals);
        }

        // Note: just deploy a erc721 for testing no need to do factory facet biz yet
        // TODO: deploy from factory
        vm.prank(nftOwner);
        erc721 = new ERC721LazyMint(true);
        erc721.initialize(nftOwner, "name", "symbol", nftOwner, 1_000, "");

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {}
}

contract ERC721LazyDropFacet_ERC721LazyDrop_ERC721LazyDrop_getClaimCondition is Setup {
    ERC721LazyDropStorage.ClaimCondition testClaimCondition;

    function _afterSetUp() internal override {
        testClaimCondition = ERC721LazyDropStorage.ClaimCondition({
            startTimestamp: 100,
            endTimestamp: 200,
            maxClaimableSupply: 100,
            supplyClaimed: 0,
            quantityLimitPerWallet: 10,
            pricePerToken: 1 ether,
            currency: address(erc20)
        });

        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);
    }

    function test_gets_claim_condition() public {
        assertEqClaimCondition(
            ERC721LazyDropFacet(address(app)).ERC721LazyDrop_getClaimCondition(address(erc721)), testClaimCondition
        );
    }

    function test_returns_empty_claim_condition_if_not_set() public {
        assertEqClaimCondition(
            ERC721LazyDropFacet(address(app)).ERC721LazyDrop_getClaimCondition(address(0)),
            ERC721LazyDropStorage.ClaimCondition({
                startTimestamp: 0,
                endTimestamp: 0,
                maxClaimableSupply: 0,
                supplyClaimed: 0,
                quantityLimitPerWallet: 0,
                pricePerToken: 0,
                currency: address(0)
            })
        );
    }
}

contract ERC721LazyDropFacet_ERC721LazyDrop_verifyClaim is Setup {
    ERC721LazyDropStorage.ClaimCondition testClaimCondition;

    function _afterSetUp() internal override {
        testClaimCondition = ERC721LazyDropStorage.ClaimCondition({
            startTimestamp: 0,
            endTimestamp: 100,
            maxClaimableSupply: 100,
            supplyClaimed: 0,
            quantityLimitPerWallet: 10,
            pricePerToken: 1 ether,
            currency: address(erc20)
        });

        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);
    }

    function test_can_verify_claim() public {
        assertTrue(
            ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(
                address(erc721), other, 1, address(erc20), 1 ether
            )
        );
    }

    function test_reverts_when_price_is_invalid() public {
        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_invalidPriceOrCurrency.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(address(erc721), other, 1, address(erc20), 0);
    }

    function test_reverts_when_currency_is_invalid() public {
        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_invalidPriceOrCurrency.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(address(erc721), other, 1, address(0), 1 ether);
    }

    function test_reverts_when_quantity_is_zero() public {
        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_quantityZeroOrExceededWalletLimit.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(address(erc721), other, 0, address(erc20), 1 ether);
    }

    function test_reverts_when_quantity_exceeds_wallet_limit() public {
        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_quantityZeroOrExceededWalletLimit.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(
            address(erc721), other, 11, address(erc20), 1 ether
        );
    }

    function test_reverts_when_quantity_exceeds_max_supply() public {
        // set max supply to 9
        testClaimCondition.maxClaimableSupply = 9;
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_exceededMaxSupply.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(
            address(erc721), other, 10, address(erc20), 1 ether
        );
    }

    function test_reverts_before_start_timestamp() public {
        testClaimCondition.startTimestamp = 1000;
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_cantClaimYet.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(
            address(erc721), other, 10, address(erc20), 1 ether
        );
    }

    function test_reverts_after_end_timestamp() public {
        testClaimCondition.endTimestamp = block.timestamp - 1;
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_claimPeriodEnded.selector);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_verifyClaim(
            address(erc721), other, 10, address(erc20), 1 ether
        );
    }
}

contract ERC721LazyDropFacet_ERC721LazyDrop_removeClaimCondition is Setup {
    ERC721LazyDropStorage.ClaimCondition testClaimCondition;

    function _afterSetUp() internal override {
        testClaimCondition = ERC721LazyDropStorage.ClaimCondition({
            startTimestamp: 0,
            endTimestamp: 100,
            maxClaimableSupply: 100,
            supplyClaimed: 0,
            quantityLimitPerWallet: 10,
            pricePerToken: 1 ether,
            currency: address(erc20)
        });

        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);
    }

    function test_removes_claim_condition() public {
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_removeClaimCondition(address(erc721));

        assertEqClaimCondition(
            ERC721LazyDropFacet(address(app)).ERC721LazyDrop_getClaimCondition(address(erc721)),
            ERC721LazyDropStorage.ClaimCondition({
                startTimestamp: 0,
                endTimestamp: 0,
                maxClaimableSupply: 0,
                supplyClaimed: 0,
                quantityLimitPerWallet: 0,
                pricePerToken: 0,
                currency: address(0)
            })
        );
    }

    function test_reverts_if_not_owner_or_admin() public {
        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_notAuthorised.selector);
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_removeClaimCondition(address(erc721));
    }
}

contract ERC721LazyDropFacet_ERC721LazyDrop_setClaimCondition is Setup {
    ERC721LazyDropStorage.ClaimCondition testClaimCondition;

    event ClaimConditionUpdated(
        address tokenContract, ERC721LazyDropStorage.ClaimCondition condition, bool resetEligibility
    );

    function _afterSetUp() internal override {
        testClaimCondition = ERC721LazyDropStorage.ClaimCondition({
            startTimestamp: 0,
            endTimestamp: 100,
            maxClaimableSupply: 10,
            supplyClaimed: 0,
            quantityLimitPerWallet: 1,
            pricePerToken: 0,
            currency: address(0)
        });
    }

    function test_can_set_claim_condition() public {
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        ERC721LazyDropStorage.ClaimCondition memory claimCondition =
            ERC721LazyDropFacet(address(app)).ERC721LazyDrop_getClaimCondition(address(erc721));

        assertEqClaimCondition(claimCondition, testClaimCondition);
    }

    function test_pays_platform_fee() public {
        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        vm.deal(nftOwner, 0.1 ether);

        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition{value: 0.1 ether}(
            address(erc721), testClaimCondition, false
        );

        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_only_token_contract_owner_can_set_claim_condition() public {
        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_notAuthorised.selector);
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);
    }

    function test_update_claim_condition() public {
        // set claim condition
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // create a new claim condition with updated startTimestamp, endTimestamp and pricePerToken
        ERC721LazyDropStorage.ClaimCondition memory newClaimCondition = testClaimCondition;
        newClaimCondition.startTimestamp = 1000;
        newClaimCondition.endTimestamp = 2000;
        newClaimCondition.pricePerToken = 1 ether;

        // update
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), newClaimCondition, true);

        ERC721LazyDropStorage.ClaimCondition memory claimCondition =
            ERC721LazyDropFacet(address(app)).ERC721LazyDrop_getClaimCondition(address(erc721));
        assertEqClaimCondition(claimCondition, newClaimCondition);
    }

    function test_emits_ClaimConditionUpdated() public {
        vm.expectEmit(true, true, true, true);
        emit ClaimConditionUpdated(address(erc721), testClaimCondition, false);
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);
    }
}

contract ERC721LazyDropFacet_ERC721LazyDrop_claim is Setup {
    bytes32 MINTER_ROLE = bytes32(uint256(1));
    ERC721LazyDropStorage.ClaimCondition testClaimCondition;

    event TokensClaimed(address tokenContract, address claimer, address receiver, uint256 quantityClaimed);

    function _afterSetUp() internal override {
        testClaimCondition = ERC721LazyDropStorage.ClaimCondition({
            startTimestamp: 0,
            endTimestamp: 100,
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
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // approve spending allowance for app
        vm.prank(other);
        erc20.approve(address(app), 1 ether);
    }

    function test_can_claim_a_token() public {
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc721.ownerOf(0), other);
    }

    function test_can_batch_claim_a_token() public {
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 2, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc721.ownerOf(0), other);
        assertEq(erc721.ownerOf(1), other);
    }

    function test_pays_price_to_recipient_with_native_token() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // make claim with ether
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim{value: 1 ether}(
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
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // make claim with ether
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim{value: 1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 0.9 ether);
        assertEq(appOwner.balance, 0.1 ether);
    }

    function test_pays_platform_fee_with_native_token() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        // make claim with ether
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim{value: 1.1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 1 ether);
        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_pays_platform_and_application_fee_with_native_token() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        // set application fee
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        // make claim with ether
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim{value: 1.1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(nftOwner.balance, 0.9 ether);
        assertEq(appOwner.balance, 0.1 ether);
        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_pays_price_to_recipient() public {
        // update claim condition price per token and currency
        testClaimCondition.pricePerToken = 1 ether;
        testClaimCondition.currency = address(erc20);
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // make claim with erc20
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc20.balanceOf(nftOwner), 1 ether);
    }

    function test_pays_application_fee() public {
        // set application fee
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        /// update claim condition price per token and currency
        testClaimCondition.pricePerToken = 1 ether;
        testClaimCondition.currency = address(erc20);
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // make claim with erc20
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc20.balanceOf(nftOwner), 0.9 ether);
        assertEq(erc20.balanceOf(appOwner), 0.1 ether);
    }

    function test_pays_platform_fee() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        testClaimCondition.currency = address(erc20);
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        // make claim with platform fee
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim{value: 0.1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc20.balanceOf(nftOwner), 1 ether);
        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_pays_platform_and_application_fee() public {
        // update claim condition price per token
        testClaimCondition.pricePerToken = 1 ether;
        testClaimCondition.currency = address(erc20);
        vm.prank(nftOwner);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_setClaimCondition(address(erc721), testClaimCondition, false);

        // set platform fee
        globals.setPlatformFee(0.1 ether, 0, socialConscienceLayer);

        // set application fee
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        // make claim with ether
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim{value: 0.1 ether}(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        assertEq(erc20.balanceOf(nftOwner), 0.9 ether);
        assertEq(erc20.balanceOf(appOwner), 0.1 ether);
        assertEq(socialConscienceLayer.balance, 0.1 ether);
    }

    function test_reverts_when_quantity_per_wallet_limit_exceeded() public {
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 2, testClaimCondition.currency, testClaimCondition.pricePerToken
        );

        vm.expectRevert(IERC721LazyDrop.ERC721LazyDrop_quantityZeroOrExceededWalletLimit.selector);
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );
    }

    function test_reverts_when_app_not_approved_minter() public {
        vm.prank(nftOwner);
        erc721.revokeRole(MINTER_ROLE, address(app));

        vm.expectRevert(ERC721LazyMint.ERC721LazyMint_notAuthorized.selector);
        vm.prank(other);
        ERC721LazyDropFacet(address(app)).ERC721LazyDrop_claim(
            address(erc721), other, 1, testClaimCondition.currency, testClaimCondition.pricePerToken
        );
    }
}

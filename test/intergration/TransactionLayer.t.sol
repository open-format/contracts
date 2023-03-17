// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

// The following tests the integration of the "transaction layer" of an application.
// The DummyDonateFacet contract inherits the platformFee and applicationFee extensions
// and demonstrates a simple implementation of a donation via the app.
// The settings facet is used to set application fee
// The globals contract is used to set the platform fee

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";

import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {Factory} from "src/factory/Factory.sol";
import {Globals} from "src/globals/Globals.sol";
import {SettingsFacet} from "src/facet/SettingsFacet.sol";
import {ERC20BaseMock} from "src/tokens/ERC20/ERC20BaseMock.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

import {PlatformFee, IPlatformFee, PlatformFeeInternal} from "src/extensions/platformFee/PlatformFee.sol";
import {
    ApplicationFee, IApplicationFee, ApplicationFeeInternal
} from "src/extensions/applicationFee/ApplicationFee.sol";

contract DummyDonateFacet is PlatformFee, ApplicationFee, ReentrancyGuard {
    function donate(address currency, uint256 price, address to)
        external
        payable
        onlyAcceptedCurrencies(currency)
        nonReentrant
    {
        (address platformFeeRecipient, uint256 platformFee) = _platformFeeInfo(price);
        (address applicationFeeRecipient, uint256 applicationFee) = _applicationFeeInfo(price);

        if (currency == CurrencyTransferLib.NATIVE_TOKEN) {
            uint256 fees = platformFee + applicationFee;
            if (fees > msg.value) {
                revert CurrencyTransferLib.CurrencyTransferLib_insufficientValue();
            }

            // pay platform fee
            CurrencyTransferLib.safeTransferNativeToken(platformFeeRecipient, platformFee);
            emit PaidPlatformFee(currency, platformFee);

            // pay application fee
            CurrencyTransferLib.safeTransferNativeToken(applicationFeeRecipient, applicationFee);
            emit PaidApplicationFee(currency, applicationFee);

            // send remaining
            CurrencyTransferLib.safeTransferNativeToken(to, msg.value - fees);
        } else {
            if (platformFee > msg.value) {
                revert CurrencyTransferLib.CurrencyTransferLib_insufficientValue();
            }

            // pay platform fee
            CurrencyTransferLib.safeTransferNativeToken(platformFeeRecipient, platformFee);
            emit PaidPlatformFee(CurrencyTransferLib.NATIVE_TOKEN, platformFee);

            // pay application fee
            CurrencyTransferLib.safeTransferERC20(currency, msg.sender, applicationFeeRecipient, applicationFee);
            emit PaidApplicationFee(currency, applicationFee);

            // Send remaining
            // shouldn't overflow because applicationFee cannot be more than 100%
            CurrencyTransferLib.safeTransferERC20(currency, msg.sender, to, price - applicationFee);
        }
    }
}

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
    address other;
    address socialConscious;

    Factory appFactory;
    Proxy template;
    Proxy app;
    RegistryMock registry;
    Globals globals;
    ERC20BaseMock erc20;

    SettingsFacet settingsFacet;
    DummyDonateFacet facet;

    uint16 tenPercentBPS = 1_000;

    function setUp() public {
        appOwner = address(0x10);
        other = address(0x11);
        socialConscious = address(0x12);

        globals = new Globals();
        registry = new RegistryMock();
        template = new  Proxy(true);
        appFactory = new Factory(address(template), address(registry), address(globals));
        erc20 = new ERC20BaseMock("Dummy", "D", 18, 1000);

        // Add Facets
        {
            settingsFacet = new SettingsFacet();
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = SettingsFacet.setApplicationFee.selector;
            selectors[1] = SettingsFacet.setAcceptedCurrencies.selector;
            registry.diamondCut(
                prepareSingleFacetCut(address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }
        {
            facet = new DummyDonateFacet();
            bytes4[] memory selectors = new bytes4[](1);
            selectors[0] = DummyDonateFacet.donate.selector;
            registry.diamondCut(
                prepareSingleFacetCut(address(facet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        // setup platform fee to be base 0.01 ether and receiver to be social Conscious
        globals.setPlatformFee(0.1 ether, 0, socialConscious);

        // create app
        vm.prank(appOwner);
        app = Proxy(payable(appFactory.create("SCLTest")));

        // set application fee
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        // set accepted tokens
        address[] memory currencies = new address[](2);
        currencies[0] = address(0); // native token
        currencies[1] = address(erc20);

        bool[] memory approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = true;

        vm.prank(appOwner);
        SettingsFacet(address(app)).setAcceptedCurrencies(currencies, approvals);
    }
}

contract TransactionLayer__integration is Setup {
    event PaidPlatformFee(address currency, uint256 amount);
    event PaidApplicationFee(address currency, uint256 amount);

    function test_pays_correct_fees() public {
        erc20.approve(address(app), 100);
        DummyDonateFacet(address(app)).donate{value: 0.1 ether}(address(erc20), 100, other);

        assertEq(socialConscious.balance, 0.1 ether);
        assertEq(erc20.balanceOf(appOwner), 10);
        assertEq(erc20.balanceOf(other), 90);
    }

    function test_pays_correct_fees_with_native_token() public {
        DummyDonateFacet(address(app)).donate{value: 1.1 ether}(address(0), 1 ether, other);

        assertEq(socialConscious.balance, 0.1 ether);
        assertEq(appOwner.balance, 0.1 ether);
        assertEq(other.balance, 0.9 ether);
    }

    function test_emits_paid_events() public {
        erc20.approve(address(app), 100);

        vm.expectEmit(true, true, true, true);
        emit PaidPlatformFee(address(0), 0.1 ether);

        vm.expectEmit(true, true, true, true);
        emit PaidApplicationFee(address(erc20), 10);

        DummyDonateFacet(address(app)).donate{value: 0.1 ether}(address(erc20), 100, other);
    }

    function test_emits_paid_events_with_naitive_token() public {
        vm.expectEmit(true, true, true, true);
        emit PaidPlatformFee(address(0), 0.1 ether);

        vm.expectEmit(true, true, true, true);
        emit PaidApplicationFee(address(0), 0.1 ether);

        DummyDonateFacet(address(app)).donate{value: 1.1 ether}(address(0), 1 ether, other);
    }
}

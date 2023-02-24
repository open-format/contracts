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
    address other;

    uint16 tenPercentBPS = 1000;

    Factory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;

    function setUp() public {
        // assign addresses
        appOwner = address(0x10);
        other = address(0x11);

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

        _afterSetUp();
    }

    function _afterSetUp() internal virtual {}
}

contract SettingsFacet__integration_setApplicationFee is Setup {
    function test_sets_application_fee() public {
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);

        (address recipient, uint256 amount) = SettingsFacet(address(app)).applicationFeeInfo(100);
        assertEq(recipient, appOwner);
        assertEq(amount, 10);
    }

    function test_revert_if_not_the_owner() public {
        vm.prank(other);
        vm.expectRevert();
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, other);
    }
}

contract SettingsFacet__integration_applicationFeeInfo is Setup {
    function _afterSetUp() internal override {
        vm.prank(appOwner);
        SettingsFacet(address(app)).setApplicationFee(tenPercentBPS, appOwner);
    }

    function test_returns_application_fee_info() public {
        (address recipient, uint256 amount) = SettingsFacet(address(app)).applicationFeeInfo(100);
        assertEq(recipient, appOwner);
        assertEq(amount, 10);
    }
}

contract SettingsFacet__integration_setAcceptedCurrencies is Setup {
    function test_sets_accepted_currencies() public {
        (address[] memory currencies, bool[] memory approvals) = _prepareAcceptedCurrencies();

        vm.prank(appOwner);
        SettingsFacet(address(app)).setAcceptedCurrencies(currencies, approvals);
    }

    function test_revert_if_not_the_owner() public {
        (address[] memory currencies, bool[] memory approvals) = _prepareAcceptedCurrencies();

        vm.prank(other);
        vm.expectRevert();
        SettingsFacet(address(app)).setAcceptedCurrencies(currencies, approvals);
    }

    function _prepareAcceptedCurrencies() internal returns (address[] memory currencies, bool[] memory approvals) {
        currencies = new address[](2);
        currencies[0] = address(0); // native token
        currencies[1] = address(0xabc);

        approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = true;
    }
}

/**
 * @dev because `SafeOwnable` contract is inherited in `SettingsFacet` we can use it's abi
 *      to call the proxy(apps) safe ownable functions
 */
contract SettingsFacet__integration_transferOwnership is Setup {
    function test_transfers_ownership() public {
        vm.prank(appOwner);
        SettingsFacet(address(app)).transferOwnership(other);

        assertEq(SettingsFacet(address(app)).nomineeOwner(), other);
    }

    function test_revert_if_not_the_owner() public {
        vm.prank(other);
        vm.expectRevert();
        SettingsFacet(address(app)).transferOwnership(other);
    }
}

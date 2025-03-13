// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that the settings facet works as intentioned within the open format contracts

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {IOwnableInternal} from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";

import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {AppFactory} from "src/factories/App.sol";
import {Globals} from "src/globals/Globals.sol";
import {SettingsFacet, IApplicationAccess, ADMIN_ROLE, OPERATOR_ROLE} from "src/facet/SettingsFacet.sol";
import {Multicall} from "src/facet/RewardsFacet.sol";
import {RedeployAllFacets} from "scripts/facet/AllFacets.s.sol";

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
    address constant openformat = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address appOwner;
    address other;

    uint16 tenPercentBPS = 1000;

    AppFactory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    function setUp() public {
        // assign addresses
        appOwner = address(0x10);
        other = address(0x11);

        vm.startPrank(openformat);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new  Proxy(true);
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        vm.stopPrank();

        RedeployAllFacets redeployAllFacets = new RedeployAllFacets();
        redeployAllFacets.runTest(address(registry));

        // create app
        vm.prank(appOwner);
        app = Proxy(payable(appFactory.create("SettingsTest", appOwner)));

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

contract SettingsFacet__integration_setCreatorAccess is Setup {
    event CreatorAccessUpdated(address[] accounts, bool[] approvals);

    function test_can_set_creator_access() public {
        (address[] memory accounts, bool[] memory approvals) = _prepareCreatorAccess();
        vm.prank(appOwner);
        SettingsFacet(address(app)).setCreatorAccess(accounts, approvals);

        assertTrue(SettingsFacet(address(app)).hasCreatorAccess(other));
    }

    function test_emits_CreatorAccessUpdated() public {
        (address[] memory accounts, bool[] memory approvals) = _prepareCreatorAccess();
        vm.expectEmit(true, true, true, true);
        emit CreatorAccessUpdated(accounts, approvals);

        vm.prank(appOwner);
        SettingsFacet(address(app)).setCreatorAccess(accounts, approvals);
    }

    function test_reverts_if_not_app_owner() public {
        (address[] memory accounts, bool[] memory approvals) = _prepareCreatorAccess();
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        vm.prank(other);
        SettingsFacet(address(app)).setCreatorAccess(accounts, approvals);
    }

    function test_reverts_if_accounts_and_approvals_length_do_not_match() public {
        (address[] memory accounts,) = _prepareCreatorAccess();
        bool[] memory approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = false;

        vm.expectRevert(IApplicationAccess.ApplicationAccess_AccountsAndApprovalsMustBeTheSameLength.selector);
        vm.prank(appOwner);
        SettingsFacet(address(app)).setCreatorAccess(accounts, approvals);
    }

    function _prepareCreatorAccess() internal returns (address[] memory accounts, bool[] memory approvals) {
        accounts = new address[](1);
        accounts[0] = address(other); // native token

        approvals = new bool[](1);
        approvals[0] = true;
    }
}

contract SettingsFacet__integration_hasCreatorAccess is Setup {
    function test_returns_true_for_app_owner() public {
        assertTrue(SettingsFacet(address(app)).hasCreatorAccess(appOwner));
    }

    function test_returns_false_for_account_without_access() public {
        assertFalse(SettingsFacet(address(app)).hasCreatorAccess(other));
    }

    function test_returns_true_for_all_accounts_when_zero_address_is_approved() public {
        address[] memory accounts = new address[](1);
        accounts[0] = address(0);

        bool[] memory approvals = new bool[](1);
        approvals[0] = true;
        vm.prank(appOwner);
        SettingsFacet(address(app)).setCreatorAccess(accounts, approvals);

        assertTrue(SettingsFacet(address(app)).hasCreatorAccess(other));
    }
}

contract SettingsFacet__integration_getGlobalsAddress is Setup {
    function test_returns_globals_address() public {
        assertEq(SettingsFacet(address(app)).getGlobalsAddress(), address(globals));
    }
}

contract SettingsFacet__integration_platformFeeInfo is Setup {
    function test_returns_platform_fee_info() public {
        // set platform base fee to 1 ether
        vm.prank(openformat);
        globals.setPlatformFee(1 ether, 0, other);

        (address recipient, uint256 amount) = SettingsFacet(address(app)).platformFeeInfo(0);

        assertEq(recipient, other);
        assertEq(amount, 1 ether);
    }
}

contract SettingsFacet__intergration_enableAccessControl is Setup {
    function test_can_enable_access_control() public {
        vm.prank(appOwner);
        SettingsFacet(address(app)).enableAccessControl();

        assertTrue(
            SettingsFacet(address(app)).hasRole(ADMIN_ROLE, appOwner)
        );
    }

    function test_reverts_if_not_app_owner() public {
        vm.prank(other);
        vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
        SettingsFacet(address(app)).enableAccessControl();
    }
}


contract SettingsFacet__intergration_grantRole is Setup {
    function test_can_grant_operator_role() public {
        vm.prank(appOwner);
        SettingsFacet(address(app)).enableAccessControl();

        vm.prank(appOwner);
        SettingsFacet(address(app)).grantRole(OPERATOR_ROLE, other);
        assertTrue(SettingsFacet(address(app)).hasRole(OPERATOR_ROLE, other));
    }

    function test_reverts_if_not_app_owner() public {
        vm.prank(appOwner);
        SettingsFacet(address(app)).enableAccessControl();

        vm.prank(other);
        vm.expectRevert(
                abi.encodePacked(
                    'AccessControl: account ',
                    vm.toString(other),
                    ' is missing role ',
                    vm.toString(ADMIN_ROLE)
                )
            );
        SettingsFacet(address(app)).grantRole(OPERATOR_ROLE, other);
    }
}

contract SettingsFacet__intergration_multicall is Setup {
    function test_can_update_multiple_settings_using_multicall() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(SettingsFacet(address(app)).enableAccessControl, ());
        calls[1] = abi.encodeCall(SettingsFacet(address(app)).grantRole, (OPERATOR_ROLE, other));

        vm.prank(appOwner);
        Multicall(address(app)).multicall(calls);

        assertTrue(SettingsFacet(address(app)).hasRole(ADMIN_ROLE, appOwner));
        assertTrue(SettingsFacet(address(app)).hasRole(OPERATOR_ROLE, other));
    }
}
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC20BaseInternal} from "lib/solidstate-solidity/contracts/token/ERC20/base/IERC20BaseInternal.sol";

import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {AppFactory} from "src/factories/App.sol";
import {Globals} from "src/globals/Globals.sol";

import {ERC721Badge} from "src/tokens/ERC721/ERC721Badge.sol";
import {IERC721Factory} from "@extensions/ERC721Factory/IERC721Factory.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {IERC20Factory} from "@extensions/ERC20Factory/IERC20Factory.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";
import {ChargeFacet} from "src/facet/ChargeFacet.sol";
import {ICharge} from "src/extensions/charge/Charge.sol";
import {SettingsFacet, IApplicationAccess} from "src/facet/SettingsFacet.sol";
import {RewardsFacet} from "src/facet/RewardsFacet.sol";

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

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

address constant OPERATOR_ADDRESS = address(0x10);
address constant USER_ADDRESS = address(0x11);
address constant OTHER_ADDRESS = address(0x12);
address constant socialConscious = address(0x13);

uint256 constant OPERATOR_BALANCE = 0;
uint256 constant USER_BALANCE = 10;
uint256 constant CHARGE_AMOUNT = 1;
uint256 constant MINIMUM_CREDIT_BALANCE = 1;
uint256 constant USER_APPROVED_SPEND = 5;
bytes32 constant CHARGE_ID = bytes32("0x123");
bytes32 constant CHARGE_TYPE = bytes32("TX");

contract Setup is Test, Helpers {
    AppFactory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;
    ChargeFacet chargeFacet;
    RewardsFacet rewardsFacet;

    ERC20Base erc20Implementation;
    bytes32 erc20ImplementationId;
    ERC20FactoryFacet erc20FactoryFacet;
    address creditContract;

    function setUp() public {
        vm.deal(OPERATOR_ADDRESS, 1 ether);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new Proxy(true);
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        erc20Implementation = new ERC20Base();
        erc20ImplementationId = bytes32("Base");
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(OPERATOR_ADDRESS);
        app = Proxy(payable(appFactory.create("RewardFacetTest", OPERATOR_ADDRESS)));

        // setup globals
        globals.setERC20Implementation(erc20ImplementationId, address(erc20Implementation));

        settingsFacet = new SettingsFacet();
        {
            // add SettingsFacet to registry
            bytes4[] memory selectors = new bytes4[](1);
            selectors[0] = settingsFacet.setCreatorAccess.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        {
            // add erc20FactoryFacet to registry
            bytes4[] memory selectors = new bytes4[](3);
            selectors[0] = erc20FactoryFacet.createERC20.selector;
            selectors[1] = erc20FactoryFacet.getERC20FactoryImplementation.selector;
            selectors[2] = erc20FactoryFacet.calculateERC20FactoryDeploymentAddress.selector;
            registry.diamondCut(
                prepareSingleFacetCut(
                    address(erc20FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
                ),
                address(0),
                ""
            );
        }

        chargeFacet = new ChargeFacet();
        {
            // add ChargeFacet to registry
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = chargeFacet.chargeUser.selector;
            selectors[1] = chargeFacet.hasFunds.selector;
            selectors[2] = chargeFacet.setMinimumCreditBalance.selector;
            selectors[3] = chargeFacet.getMinimumCreditBalance.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(chargeFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        rewardsFacet = new RewardsFacet();
        {
            // add RewardsFacet to registry
            bytes4[] memory selectors = new bytes4[](1);
            selectors[0] = rewardsFacet.multicall.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(rewardsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        // use app to create erc20 contract
        vm.prank(OPERATOR_ADDRESS);
        creditContract = ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 0, erc20ImplementationId);

        _afterSetup();
    }

    /**
     * @dev override to add more setup per test contract
     */
    function _afterSetup() internal virtual {}
}

contract ChargeFacet__integration_chargeUser is Setup {
    event chargedUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType);

    function _afterSetup() internal override {
        // Give user a balance
        vm.prank(OPERATOR_ADDRESS);
        ERC20Base(creditContract).mintTo(USER_ADDRESS, USER_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(OPERATOR_ADDRESS), OPERATOR_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), USER_BALANCE);

        // User approves allowance spend for app
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).approve(address(app), USER_APPROVED_SPEND);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), USER_APPROVED_SPEND);
    }

    function test_operator_charges_user() public {
        // Operator charges credits
        vm.prank(OPERATOR_ADDRESS);
        ChargeFacet(address(app)).chargeUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, CHARGE_ID, CHARGE_TYPE);

        // Charge amount is removed from USER_ADDRESS
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), USER_BALANCE - CHARGE_AMOUNT);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), USER_APPROVED_SPEND - CHARGE_AMOUNT);

        // Charge amount is added to OPERATOR_ADDRESS
        assertEq(ERC20Base(creditContract).balanceOf(OPERATOR_ADDRESS), OPERATOR_BALANCE + CHARGE_AMOUNT);
    }

    function test_emits_charged_user_event() public {
        vm.expectEmit(true, true, true, true, address(app));
        emit chargedUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, CHARGE_ID, CHARGE_TYPE);

        // Operator charges credits
        vm.prank(OPERATOR_ADDRESS);
        ChargeFacet(address(app)).chargeUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, CHARGE_ID, CHARGE_TYPE);
    }

    function test_reverts_when_user_has_insufficient_allowance() public {
        // Set user allowance to zero
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).approve(address(app), 0);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), 0);

        // Operator fails to charge user
        vm.prank(OPERATOR_ADDRESS);
        vm.expectRevert(IERC20BaseInternal.ERC20Base__InsufficientAllowance.selector);
        ChargeFacet(address(app)).chargeUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, CHARGE_ID, CHARGE_TYPE);
    }

    function test_reverts_when_user_has_insufficient_balance() public {
        // User transfers funds so balance is 0
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).transfer(OTHER_ADDRESS, USER_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), 0);

        // Operator fails to charge user
        vm.prank(OPERATOR_ADDRESS);
        vm.expectRevert(IERC20BaseInternal.ERC20Base__TransferExceedsBalance.selector);
        ChargeFacet(address(app)).chargeUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, CHARGE_ID, CHARGE_TYPE);
    }

    function test_reverts_when_caller_is_not_operator() public {
        // User approves allowance spend for app
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).approve(address(app), USER_APPROVED_SPEND);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), USER_APPROVED_SPEND);

        // Other fails to charge user
        vm.prank(OTHER_ADDRESS);
        vm.expectRevert(ICharge.Charge_doNotHavePermission.selector);
        ChargeFacet(address(app)).chargeUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, CHARGE_ID, CHARGE_TYPE);
    }
}

contract ChargeFacet__integration_hasFunds is Setup {
    function _afterSetup() internal override {
        // set minimum credit balance
        vm.prank(OPERATOR_ADDRESS);
        ChargeFacet(address(app)).setMinimumCreditBalance(creditContract, MINIMUM_CREDIT_BALANCE);

        // Give user a balance
        vm.prank(OPERATOR_ADDRESS);
        ERC20Base(creditContract).mintTo(USER_ADDRESS, USER_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(OPERATOR_ADDRESS), OPERATOR_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), USER_BALANCE);

        // User approves allowance spend for app
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).approve(address(app), USER_APPROVED_SPEND);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), USER_APPROVED_SPEND);
    }

    function test_returns_true_when_user_has_sufficient_balance_and_allowance() public {
        assertTrue(ChargeFacet(address(app)).hasFunds(USER_ADDRESS, creditContract));
    }

    function test_returns_true_when_minimum_credit_balance_is_set_to_zero() public {
        // Set minimum credit balance to zero
        vm.prank(OPERATOR_ADDRESS);
        ChargeFacet(address(app)).setMinimumCreditBalance(creditContract, 0);

        assertTrue(ChargeFacet(address(app)).hasFunds(OTHER_ADDRESS, creditContract));
    }

    function test_returns_false_when_user_has_insufficient_balance() public {
        // User transfers funds so balance is 0
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).transfer(OTHER_ADDRESS, USER_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), 0);

        assertFalse(ChargeFacet(address(app)).hasFunds(USER_ADDRESS, creditContract));
    }

    function test_returns_false_when_user_has_insufficient_allowance() public {
        // User sets app allowance to 0
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).approve(address(app), 0);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), 0);

        assertFalse(ChargeFacet(address(app)).hasFunds(USER_ADDRESS, creditContract));
    }

    function test_returns_false_when_user_has_insufficient_allowance_and_balance() public {
        assertFalse(ChargeFacet(address(app)).hasFunds(OTHER_ADDRESS, creditContract));
    }
}

contract ChargeFacet__integration_setMinimumCreditBalance is Setup {
    event minimumCreditBalanceUpdated(address credit, uint256 balance);

    function test_sets_minimum_credit_balance() public {
        vm.prank(OPERATOR_ADDRESS);
        ChargeFacet(address(app)).setMinimumCreditBalance(creditContract, MINIMUM_CREDIT_BALANCE);

        assertEq(ChargeFacet(address(app)).getMinimumCreditBalance(creditContract), MINIMUM_CREDIT_BALANCE);
    }

    function test_emits_minimum_credit_balance_updated_event() public {
        vm.expectEmit(true, true, true, true, address(app));
        emit minimumCreditBalanceUpdated(creditContract, MINIMUM_CREDIT_BALANCE);

        vm.prank(OPERATOR_ADDRESS);
        ChargeFacet(address(app)).setMinimumCreditBalance(creditContract, MINIMUM_CREDIT_BALANCE);
    }

    function test_reverts_when_caller_is_not_the_operator() public {
        vm.expectRevert(ICharge.Charge_doNotHavePermission.selector);

        vm.prank(OTHER_ADDRESS);
        ChargeFacet(address(app)).setMinimumCreditBalance(creditContract, MINIMUM_CREDIT_BALANCE);
    }
}

contract ChargeFacet__integration_multicall is Setup {
    event chargedUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType);

    function _afterSetup() internal override {
        // Give user a balance
        vm.prank(OPERATOR_ADDRESS);
        ERC20Base(creditContract).mintTo(USER_ADDRESS, USER_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(OPERATOR_ADDRESS), OPERATOR_BALANCE);
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), USER_BALANCE);

        // User approves allowance spend for app
        vm.prank(USER_ADDRESS);
        ERC20Base(creditContract).approve(address(app), USER_APPROVED_SPEND);
        assertEq(ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), USER_APPROVED_SPEND);
    }

    function test_charges_users_with_multicall() public {
        uint256 numberOfCharges = 5;
        uint256 totalAmountCharged = CHARGE_AMOUNT * numberOfCharges;

        // construct multicall
        bytes[] memory calls = new bytes[](numberOfCharges);
        for (uint256 i = 0; i < numberOfCharges; i++) {
            calls[i] = abi.encodeCall(
                ChargeFacet(address(app)).chargeUser,
                (USER_ADDRESS, creditContract, CHARGE_AMOUNT, bytes32(i), CHARGE_TYPE)
            );
        }

        // expect emits to match number of charges
        vm.expectEmit(true, true, true, true, address(app));
        for (uint256 i = 0; i < numberOfCharges; i++) {
            emit chargedUser(USER_ADDRESS, creditContract, CHARGE_AMOUNT, bytes32(i), CHARGE_TYPE);
        }

        vm.prank(OPERATOR_ADDRESS);
        RewardsFacet(address(app)).multicall(calls);

        // Charge amount is removed from USER_ADDRESS
        assertEq(ERC20Base(creditContract).balanceOf(USER_ADDRESS), USER_BALANCE - totalAmountCharged);
        assertEq(
            ERC20Base(creditContract).allowance(USER_ADDRESS, address(app)), USER_APPROVED_SPEND - totalAmountCharged
        );

        // Charge amount is added to OPERATOR_ADDRESS
        assertEq(ERC20Base(creditContract).balanceOf(OPERATOR_ADDRESS), OPERATOR_BALANCE + totalAmountCharged);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

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
import {SettingsFacet, IApplicationAccess} from "src/facet/SettingsFacet.sol";

import {Deploy} from "scripts/core/Globals.s.sol";

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

/**
 * @dev dummy contract to test platform fee is not paid when called from a contract
 *      must first grant MINTER_ROLE to this contract
 */
contract MinterDummy {
    function mintTo(address _erc20, address _account, uint256 _amount) public {
        ERC20Base(_erc20).mintTo(_account, _amount);
    }
}

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

contract Setup is Test, Helpers {
    address creator;
    address other;
    address socialConscious;

    AppFactory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;
    ChargeFacet chargeFacet;

    ERC20Base erc20Implementation;
    bytes32 erc20ImplementationId;
    ERC20FactoryFacet erc20FactoryFacet;
    address creditContract;

    function setUp() public {
        // assign addresses
        creator = address(0x10);
        other = address(0x11);
        socialConscious = address(0x12);

        vm.deal(creator, 1 ether);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new Proxy(true);
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        erc20Implementation = new ERC20Base();
        erc20ImplementationId = bytes32("Base");
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("RewardFacetTest", creator)));

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

        chargeFacet = new ChargeFacet();
        {
            // add ChargeFacet to registry
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = chargeFacet.chargeUser.selector;
            selectors[1] = chargeFacet.chargeApp.selector;
            selectors[2] = chargeFacet.hasFunds.selector;
            selectors[3] = chargeFacet.userHasFunds.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(chargeFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
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

        // use app to create erc20 contract
        vm.prank(creator);
        creditContract =
            ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);

        _afterSetup();
    }

    /**
     * @dev override to add more setup per test contract
     */
    function _afterSetup() internal virtual {}
}

contract CreditFacet__integration_chargeUser is Setup {
    event chargedUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType );
    event chargedApp(address operator, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType );

    function _afterSetup() internal override {
        // user is "rewarded" 100 credits
        vm.prank(creator);
        ERC20Base(creditContract).transfer(other, 100);

        assertEq(ERC20Base(creditContract).balanceOf(creator), 900);
        assertEq(ERC20Base(creditContract).balanceOf(other), 100);
    }

    function test_operator_can_charge_user() public {
        // user approves allowance spend for app
        vm.prank(other);
        ERC20Base(creditContract).approve(address(app), 100);
        assertEq(ERC20Base(creditContract).allowance(other, address(app)), 100);

        // operator charges 10 credits
        vm.prank(creator);
        ChargeFacet(address(app)).chargeUser(other, creditContract, 10, "10TX", "Batch");

        assertEq(ERC20Base(creditContract).balanceOf(other), 90);
        assertEq(ERC20Base(creditContract).allowance(other, address(app)), 90);

        // charge amount is sent to operator
        assertEq(ERC20Base(creditContract).balanceOf(creator), 910);
    }

    function test_should_revert_if_insufficient_allowance() public {
        // user approves allowance spend for app
        vm.prank(other);
        ERC20Base(creditContract).approve(address(app), 9);
         assertEq(ERC20Base(creditContract).allowance(other, address(app)), 9);

        // operator fails to charge 10 credits as allowance is only 9
        vm.prank(creator);
        vm.expectRevert();
        ChargeFacet(address(app)).chargeUser(other, creditContract, 10, "10TX", "Batch");

        assertEq(ERC20Base(creditContract).balanceOf(other), 100);
        assertEq(ERC20Base(creditContract).allowance(other, address(app)), 9);
        assertEq(ERC20Base(creditContract).balanceOf(creator), 900);
    }

    function test_should_revert_if_insufficient_balance() public {
        // user approves allowance spend for app and transfers funds so balance is 0
        vm.prank(other);
        ERC20Base(creditContract).approve(address(app), 100);
        assertEq(ERC20Base(creditContract).allowance(other, address(app)), 100);
        vm.prank(other);
        ERC20Base(creditContract).transfer(address(creator), 100);
        assertEq(ERC20Base(creditContract).balanceOf(other), 0);

        // operator fails to charge user
        vm.prank(creator);
        vm.expectRevert();
        ChargeFacet(address(app)).chargeUser(other, creditContract, 100, "100TX", "Batch");
    }

    function test_should_revert_if_caller_is_not_app_owner() public {
        // user approves allowance spend for app
        vm.prank(other);
        ERC20Base(creditContract).approve(address(app), 100);
        assertEq(ERC20Base(creditContract).allowance(other, address(app)), 100);

        // user fails to charge themselves
        vm.prank(other);
        vm.expectRevert();
        ChargeFacet(address(app)).chargeUser(other, creditContract, 100, "100TX", "Batch");
    }
}

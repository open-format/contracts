// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// The following tests that the platform fee extension works as intentended within the ecosystem

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

import {IERC20Factory} from "@extensions/ERC20Factory/IERC20Factory.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";

// bad erc20 implementation without an initialize function
contract BadERC20 {}

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
    address creator;
    address other;
    address socialConscious;

    Factory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    ERC20Base erc20Implementation;
    bytes32 erc20ImplementationId;
    ERC20FactoryFacet erc20FactoryFacet;

    function setUp() public {
        // assign addresses
        creator = address(0x10);
        creator = address(0x11);
        socialConscious = address(0x12);

        vm.deal(creator, 1 ether);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new  Proxy(true);
        appFactory = new Factory(address(appImplementation), address(registry), address(globals));

        erc20Implementation = new ERC20Base();
        erc20ImplementationId = bytes32("base");
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("platformFeeTest")));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC20Implementation(erc20ImplementationId, address(erc20Implementation));

        // add facet to registry
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = erc20FactoryFacet.createERC20.selector;
        selectors[1] = erc20FactoryFacet.getERC20FactoryImplementation.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(erc20FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );
    }
}

contract ERC20FactoryFacet__integration_createERC20 is Setup {
    function test_can_create_erc20() public {
        vm.prank(creator);
        address erc20Address =
            ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);

        assertEq(ERC20Base(erc20Address).name(), "name");
        assertEq(ERC20Base(erc20Address).symbol(), "symbol");
        assertEq(ERC20Base(erc20Address).decimals(), 18);
        assertEq(ERC20Base(erc20Address).totalSupply(), 1000);
        assertEq(ERC20Base(erc20Address).balanceOf(creator), 1000);
    }

    function test_can_create_erc20_and_pay_platform_fee() public {
        // set platform base fee to 1 ether
        globals.setPlatformFee(1 ether, 0, socialConscious);

        // create nft and pay platform fee
        vm.prank(creator);
        address erc20Address = ERC20FactoryFacet(address(app)).createERC20{value: 1 ether}(
            "name", "symbol", 18, 1000, erc20ImplementationId
        );
        // check platform fee has been received
        assertEq(socialConscious.balance, 1 ether);
    }

    function test_reverts_when_do_not_have_permission() public {
        vm.expectRevert(IERC20Factory.Error_do_not_have_permission.selector);
        vm.prank(other);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
    }

    function test_reverts_when_no_implementation_is_found() public {
        vm.expectRevert(IERC20Factory.Error_no_implementation_found.selector);
        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, bytes32("wrong implementation id"));
    }

    function test_reverts_when_name_is_already_used() public {
        // create first erc20
        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);

        vm.expectRevert(IERC20Factory.Error_name_already_used.selector);
        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
    }

    function test_reverts_when_erc20_implementation_is_incompatible() public {
        BadERC20 badErc20Implementation = new BadERC20();
        bytes32 badErc20ImplementationId = bytes32("bad");

        globals.setERC20Implementation(badErc20ImplementationId, address(badErc20Implementation));

        vm.expectRevert(IERC20Factory.Error_failed_to_initialize.selector);
        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, badErc20ImplementationId);
    }
}

contract ERC20FactoryFacet__integration_getERC20FactoryImplementation is Setup {
    function test_returns_implementation_address() public {
        address implementation = ERC20FactoryFacet(address(app)).getERC20FactoryImplementation(erc20ImplementationId);
        assertEq(implementation, address(erc20Implementation));
    }

    function test_returns_zero_address_if_no_implementation_found() public {
        address implementation = ERC20FactoryFacet(address(app)).getERC20FactoryImplementation("");
        assertEq(implementation, address(0));
    }
}

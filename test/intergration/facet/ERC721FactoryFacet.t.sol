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

import {IERC721Factory} from "@extensions/ERC721Factory/IERC721Factory.sol";
import {ERC721Base} from "src/tokens/ERC721/ERC721Base.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";

// bad erc721 implementation without an initialize function
contract BadERC721 {}

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

    ERC721Base erc721Implementation;
    bytes32 erc721ImplementationId;
    ERC721FactoryFacet erc721FactoryFacet;

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

        erc721Implementation = new ERC721Base();
        erc721ImplementationId = bytes32("base");
        erc721FactoryFacet = new ERC721FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("platformFeeTest")));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC721Implementation(erc721ImplementationId, address(erc721Implementation));

        // add facet to registry
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );
    }
}

contract ERC721FactoryFacet__integration_createERC721 is Setup {
    function test_can_create_erc721() public {
        vm.prank(creator);
        address erc721Address =
            ERC721FactoryFacet(address(app)).createERC721("name", "symbol", creator, 1000, erc721ImplementationId);

        assertEq(ERC721Base(erc721Address).name(), "name");
        assertEq(ERC721Base(erc721Address).symbol(), "symbol");
        (address receiver, uint256 royaltyAmount) = ERC721Base(erc721Address).royaltyInfo(0, 1 ether);
        assertEq(receiver, creator);
        assertEq(royaltyAmount, 0.1 ether);
        assertEq(ERC721Base(erc721Address).owner(), creator);
    }

    function test_can_create_erc721_and_pay_platform_fee() public {
        // set platform base fee to 1 ether
        globals.setPlatformFee(1 ether, 0, socialConscious);

        // create nft and pay platform fee
        vm.prank(creator);
        address erc721Address = ERC721FactoryFacet(address(app)).createERC721{value: 1 ether}(
            "name", "symbol", creator, 1000, erc721ImplementationId
        );
        // check platform fee has been received
        assertEq(socialConscious.balance, 1 ether);
    }

    function test_reverts_when_do_not_have_permission() public {
        vm.expectRevert(IERC721Factory.Error_do_not_have_permission.selector);
        vm.prank(other);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", creator, 1000, erc721ImplementationId);
    }

    function test_reverts_when_no_implementation_is_found() public {
        vm.expectRevert(IERC721Factory.Error_no_implementation_found.selector);
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721(
            "name", "symbol", creator, 1000, bytes32("wrong implementation id")
        );
    }

    function test_reverts_when_name_is_already_used() public {
        // create first erc721
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", creator, 1000, erc721ImplementationId);

        vm.expectRevert(IERC721Factory.Error_name_already_used.selector);
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", creator, 1000, erc721ImplementationId);
    }

    function test_reverts_when_erc721_implementation_is_incompatible() public {
        BadERC721 badErc721Implementation = new BadERC721();
        bytes32 badErc721ImplementationId = bytes32("bad");

        globals.setERC721Implementation(badErc721ImplementationId, address(badErc721Implementation));

        vm.expectRevert(IERC721Factory.Error_failed_to_initialize.selector);
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721{value: 1 ether}(
            "name", "symbol", creator, 1000, badErc721ImplementationId
        );
    }
}

contract ERC721FactoryFacet__integration_getERC721FactoryImplementation is Setup {
    function test_returns_implementation_address() public {
        address implementation = ERC721FactoryFacet(address(app)).getERC721FactoryImplementation(erc721ImplementationId);
        assertEq(implementation, address(erc721Implementation));
    }

    function test_returns_zero_address_if_no_implementation_found() public {
        address implementation = ERC721FactoryFacet(address(app)).getERC721FactoryImplementation("");
        assertEq(implementation, address(0));
    }
}

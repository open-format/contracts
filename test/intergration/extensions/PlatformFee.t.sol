// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// The following tests that proxy and registry contracts work together as intended

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

import {PlatformFee, IPlatformFee} from "src/extensions/platformFee/PlatformFee.sol";

contract DummyFacet is PlatformFee {
    string public message = "";

    function purchase(uint256 _price) external payable {
        _payPlatfromFee(_price);
    }

    function write() external payable {
        _payPlatfromFee(0);
    }

    function read() external view returns (string memory) {
        return message;
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
    address creator;
    address socialConscious;

    Factory appFactory;
    Proxy template;
    Proxy app;
    RegistryMock registry;
    DummyFacet facet;
    Globals globals;

    function setUp() public {
        creator = address(0x10);
        socialConscious = address(0x11);

        globals = new Globals();
        registry = new RegistryMock();
        template = new  Proxy(true);
        appFactory = new Factory(address(template), address(registry), address(globals));
        facet = new DummyFacet();

        // add facet to registry
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = DummyFacet.write.selector;
        selectors[1] = DummyFacet.purchase.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(facet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );

        // setup platform fee to be base 0.01 ether and reciever to be social Conscious
        globals.setPlatformFee(0.1 ether, 0, socialConscious);

        // create app
        app = Proxy(payable(appFactory.create("platformFeeTest")));
    }
}

contract PlatformFee__intergration is Setup, IPlatformFee {
    function test_platform_fee_is_paid() public {
        DummyFacet(address(app)).write{value: 0.1 ether}();

        assertEq(socialConscious.balance, 0.1 ether);
    }

    function test_exact_platform_fee_is_paid() public {
        DummyFacet(address(app)).write{value: 10 ether}();

        assertEq(socialConscious.balance, 0.1 ether);
    }

    function test_platform_percentage_fee_is_paid() public {
        uint16 tenPercentBPS = 1000;
        globals.setPlatformFee(0, tenPercentBPS, socialConscious);

        DummyFacet(address(app)).purchase{value: 1 ether}(1 ether);
        assertEq(socialConscious.balance, 0.1 ether);
    }

    function test_platform_percentage_fee_is_zero_when_price_is_zero() public {
        uint16 tenPercentBPS = 1000;
        globals.setPlatformFee(0, tenPercentBPS, socialConscious);

        DummyFacet(address(app)).purchase{value: 0 ether}(0 ether);
        assertEq(socialConscious.balance, 0 ether);
    }

    function test_platform_percentage_and_base_fee_is_paid() public {
        uint16 tenPercentBPS = 1000;
        globals.setPlatformFee(0.1 ether, tenPercentBPS, socialConscious);

        DummyFacet(address(app)).purchase{value: 1 ether}(1 ether);
        assertEq(socialConscious.balance, 0.2 ether);
    }

    function test_emits_paid_platform_fee_event() public {
        vm.expectEmit(true, true, true, true, address(app));
        emit PaidPlatformFee(address(0), 0.1 ether);

        DummyFacet(address(app)).write{value: 0.1 ether}();
    }

    function test_reverts_when_value_is_less_than_amount() public {
        vm.expectRevert(Error_insufficientValue.selector);
        DummyFacet(address(app)).write{value: 0.001 ether}();
    }

    function test_reverts_when_no_value_is_sent() public {
        vm.expectRevert(Error_insufficientValue.selector);
        DummyFacet(address(app)).write();
    }

    function test_reverts_when_value_is_less_than_amount_and_contract_has_sufficiant_balance() public {
        vm.deal(address(app), 1 ether);

        vm.expectRevert(Error_insufficientValue.selector);
        DummyFacet(address(app)).write();
    }
}

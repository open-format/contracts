// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// The following tests that proxy applys a base fee to every transaction

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {ProxyBaseFeeMock} from "../../src/proxy/ProxyBaseFeeMock.sol";
import {RegistryMock} from "../../src/registry/RegistryMock.sol";
import {Globals} from "../../src/globals/Globals.sol";
import {Factory} from "../../src/factory/Factory.sol";

contract DummyFacet {
    string public message = "";

    function write(string memory _message) external {
        message = _message;
    }

    function writePayable(string memory _message) external payable {
        message = _message;
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

contract setup is Test, Helpers {
    Factory appFactory;
    ProxyBaseFeeMock template;
    ProxyBaseFeeMock app;
    RegistryMock registry;
    Globals globals;
    DummyFacet facet;

    address reciever;
    address creator;
    address other;

    function setUp() public {
        // deploy needed contracts
        globals = new Globals();
        registry = new RegistryMock();
        template = new  ProxyBaseFeeMock(address(registry), address(globals));
        appFactory = new Factory(address(template), address(registry), address(globals));
        facet = new DummyFacet();

        // setup addreses
        reciever = address(0x10);
        creator = address(0x11);
        other = address(0x12);

        // add dummy facet to registry
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = DummyFacet.write.selector;
        selectors[1] = DummyFacet.writePayable.selector;
        selectors[2] = DummyFacet.read.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(facet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );

        // setup baseFee globals
        globals.setBaseFee(0);
        globals.setBaseFeeReciver(payable(reciever));

        // create app from factory
        vm.prank(creator);
        app = ProxyBaseFeeMock(payable(appFactory.create("salt")));
    }
}

contract Proxy__base_fee_intergration is setup {
    function test_can_interact_with_facet() public {
        DummyFacet(address(app)).write("hello");
        assertEq(DummyFacet(address(app)).read(), "hello");
    }

    function test_sends_base_fee_to_reciever_with_payable_function() public {
        uint256 baseFee = 0.1 ether;
        globals.setBaseFee(baseFee);
        // Cannot set option "value" on a non-payable function type.
        DummyFacet(address(app)).writePayable{value: baseFee}("hello");

        assertEq(reciever.balance, baseFee);
    }

    function test_reverts_sending_base_fee_to_reciever_with_non_payable_function() public {
        uint256 baseFee = 0.1 ether;
        globals.setBaseFee(baseFee);

        // Compiler Error: Cannot set option "value" on a non-payable function type
        // DummyFacet(address(app)).write{value: baseFee}("hello");

        // force it by using low level call
        (bool ok,) = address(app).call{value: baseFee}(abi.encodeWithSelector(DummyFacet.write.selector, "hello"));
        assertFalse(ok);

        // reciever gets nothing
        assertEq(reciever.balance, 0);
    }

    function test_view_function_cannot_be_called_from_contract() public {
        uint256 baseFee = 0.1 ether;
        globals.setBaseFee(baseFee);

        vm.expectRevert("must pay base fee");
        DummyFacet(address(app)).read();
    }
}

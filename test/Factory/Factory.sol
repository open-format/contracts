// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

// The following tests that proxy and registry contracts work together as intended

import "forge-std/Test.sol";
import {Factory, IFactory} from "../../src/factory/Factory.sol";

contract DummyImplementation {
    address public owner;

    function init(address _owner, address _registry, address _globals) external {
        owner = _owner;
    }

    function boop() external pure returns (string memory) {
        return "boop";
    }
}

contract Setup is Test {
    address creator;

    Factory factory;
    DummyImplementation implementation;

    function setUp() public {
        creator = address(0x10);

        implementation = new DummyImplementation();
        factory = new Factory(address(implementation), address(0), address(0));
    }
}

contract Factory__create is Setup, IFactory {
    function test_creates_minmal_proxy_of_implementation() public {
        address minimalProxy = factory.create("app_name");
        assertEq(DummyImplementation(minimalProxy).boop(), "boop");
    }

    function test_emits_created_event() public {
        /**
         * @dev id is determinastic and derived from factory address and name
         */
        address id = 0x2bC632E15Eb74471E9C40D3915c7Dfae878D681c;

        /**
         * @dev the name param in the Created event is converted from bytes32 to string
         *      in the create function. To ensure vm.expectEmit matches the event data
         *      we have to also zero pad the string to 32 bytes.
         */
        string memory zeroPaddedAppName = string(abi.encodePacked(bytes32("app_name")));

        vm.expectEmit(true, true, true, true);
        emit Created(id, creator, zeroPaddedAppName);

        vm.prank(creator);
        factory.create("app_name");
    }

    function test_reverts_if_name_already_used() public {
        factory.create("app_name");

        vm.expectRevert("name already used");
        factory.create("app_name");
    }
}

contract Factory__apps is Setup {
    function test_can_get_address_via_name() public {
        address minimalProxy = factory.create("app_name");
        assertEq(factory.apps("app_name"), minimalProxy);
    }

    function test_returns_zero_address_if_name_is_free() public {
        assertEq(factory.apps("app_name"), address(0));
    }
}
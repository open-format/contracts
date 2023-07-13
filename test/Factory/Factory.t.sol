// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that proxy and registry contracts work together as intended

import "forge-std/Test.sol";
import {Factory, IFactory} from "../../src/factory/Factory.sol";
import {ERC20ConstellationMock} from "../../src/tokens/ERC20/ERC20ConstellationMock.sol";

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
    ERC20ConstellationMock erc20ConstellationMock;

    function setUp() public {
        creator = address(0x10);

        implementation = new DummyImplementation();
        factory = new Factory(address(implementation), address(0), address(0));
        erc20ConstellationMock = new ERC20ConstellationMock("ConstellationA", "A", 18, 1000);
    }
}

contract Factory__create is Setup, IFactory {
    function test_creates_minmal_proxy_of_implementation() public {
        address minimalProxy = factory.create("app_name", address(erc20ConstellationMock), address(0));
        assertEq(DummyImplementation(minimalProxy).boop(), "boop");
    }

    function test_can_create_with_the_same_name_from_different_accounts() public {
        factory.create("app_name", address(erc20ConstellationMock), address(0));

        vm.prank(creator);
        factory.create("app_name", address(erc20ConstellationMock), creator);
    }

    function test_emits_created_event() public {
        // get deployment address by calling `calculateDeploymentAddress` from creators wallet
        vm.prank(creator);
        address id = factory.calculateDeploymentAddress(creator, "app_name");

        string memory zeroPaddedAppName = string(abi.encodePacked(bytes32("app_name")));

        vm.expectEmit(true, true, true, true);
        emit Created(id, creator, zeroPaddedAppName, address(erc20ConstellationMock));

        vm.prank(creator);
        factory.create("app_name", address(erc20ConstellationMock), creator);
    }

    function test_reverts_if_name_already_used_by_same_account() public {
        factory.create("app_name", address(erc20ConstellationMock), address(0));

        vm.expectRevert(IFactory.Factory_nameAlreadyUsed.selector);
        factory.create("app_name", address(erc20ConstellationMock), address(0));
    }
}

contract Factory__apps is Setup {
    function test_can_get_address_via_hash_of_address_and_name() public {
        vm.prank(creator);
        address minimalProxy = factory.create("app_name", address(erc20ConstellationMock), creator);

        bytes32 id = keccak256(abi.encode(creator, bytes32("app_name")));
        assertEq(factory.apps(id), minimalProxy);
    }

    function test_returns_zero_address_if_name_is_free() public {
        assertEq(factory.apps(keccak256(abi.encode(creator, bytes32("app_name")))), address(0));
    }
}

contract Factory__calculateDeploymentAddress is Setup {
    function test_can_get_address_of_deployment() public {
        vm.prank(creator);
        address expectedAddress = factory.calculateDeploymentAddress(creator, "app_name");

        vm.prank(creator);
        address minimalProxy = factory.create("app_name", address(erc20ConstellationMock), creator);

        assertEq(expectedAddress, minimalProxy);
    }

    function test_reverts_when_name_is_already_used() public {
        vm.prank(creator);
        address minimalProxy = factory.create("app_name", address(erc20ConstellationMock), creator);

        vm.expectRevert(IFactory.Factory_nameAlreadyUsed.selector);
        vm.prank(creator);
        factory.calculateDeploymentAddress(creator, "app_name");
    }
}

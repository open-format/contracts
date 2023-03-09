// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IRegistry} from "../../src/registry/IRegistry.sol";
import {RegistryMock} from "../../src/registry/RegistryMock.sol";

contract Registry__fallback is Test {
    RegistryMock registry;

    function setUp() public {
        registry = new RegistryMock();
    }

    function test_fallback_is_reverted() public {
        (bool ok, bytes memory resp) = address(registry).delegatecall(abi.encodeWithSignature("function()"));
        assertFalse(ok);

        // not sure if this is actually readable off-chain
        bytes32 respHash = (keccak256(resp));
        bytes32 errorHash =
            (keccak256(abi.encodePacked(IRegistry.Registry_cannotInteractWithRegistryDirectly.selector)));
        assertEq(respHash, errorHash);
    }
}

contract Registry__withdraw is Test {
    address owner = address(0x10);
    address other = address(0x11);

    RegistryMock registry;

    function setUp() public {
        vm.prank(owner);
        registry = new RegistryMock();
        vm.deal(address(registry), 1 ether);
    }

    function test_can_withdraw_ether() public {
        vm.prank(owner);
        registry.withdraw();
        assertEq(owner.balance, 1 ether);
    }

    function test_only_owner_can_withdraw_ether() public {
        vm.prank(other);
        vm.expectRevert();
        registry.withdraw();
    }
}

contract Registry__recieve is Test {
    RegistryMock registry;

    function setUp() public {
        registry = new RegistryMock();
    }

    function test_can_recieve_ether() public {
        payable(registry).transfer(1 ether);
        assertEq(address(registry).balance, 1 ether);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that proxy and registry contracts work together as intended

import "forge-std/Test.sol";
import {ConstellationFactory, IConstellation} from "../../src/factories/Constellation.sol";
import {ERC20Base} from "../../src/tokens/ERC20/ERC20Base.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

contract Setup is Test {
    address creator;

    ConstellationFactory factory;
    ERC20Base erc20Implementation;
    address constellation;

    function setUp() public {
        creator = address(0x10);

        erc20Implementation = new ERC20Base();
        factory = new ConstellationFactory(address(erc20Implementation), address(0));
        constellation = factory.create("Constellation", "CSTN", 18, 1000);
    }
}

contract Factory__create is Setup, IConstellation {
    function test_creates_minmal_proxy_of_implementation() public {
        address minimalProxy = factory.create("constellation_A", "CA", 18, 1000);
        assertEq(IERC20(minimalProxy).totalSupply(), 1000);
    }

    function test_can_create_with_the_same_name_from_different_accounts() public {
        factory.create("constellation_A", "CA", 18, 1000);

        vm.prank(creator);
        factory.create("constellation_A", "CA", 18, 1000);
    }

    function test_emits_created_event() public {
        // get deployment address by calling `calculateDeploymentAddress` from creators wallet
        vm.prank(creator);
        address id = factory.calculateDeploymentAddress(creator, "constellation_A");

        string memory zeroPaddedAppName = string(abi.encodePacked(bytes32("constellation_A")));

        vm.expectEmit(true, true, true, true);
        emit Created(id, creator, zeroPaddedAppName);

        vm.prank(creator);
        factory.create("constellation_A", "CA", 18, 1000);
    }

    function test_reverts_if_name_already_used_by_same_account() public {
        factory.create("constellation_A", "CA", 18, 1000);

        vm.expectRevert(IConstellation.Constellation_NameAlreadyUsed.selector);
        factory.create("constellation_A", "CA", 18, 1000);
    }
}

contract Factory__apps is Setup {
    function test_can_get_address_via_hash_of_address_and_name() public {
        vm.prank(creator);
        address minimalProxy = factory.create("constellation_A", "CA", 18, 1000);

        bytes32 id = keccak256(abi.encode(creator, bytes32("constellation_A")));
        assertEq(factory.constellations(id), minimalProxy);
    }

    function test_returns_zero_address_if_name_is_free() public {
        assertEq(factory.constellations(keccak256(abi.encode(creator, bytes32("constellation_A")))), address(0));
    }
}

contract Factory__calculateDeploymentAddress is Setup {
    function test_can_get_address_of_deployment() public {
        vm.prank(creator);
        address expectedAddress = factory.calculateDeploymentAddress(creator, "constellation_A");

        vm.prank(creator);
        address minimalProxy = factory.create("constellation_A", "CA", 18, 1000);
        assertEq(expectedAddress, minimalProxy);
    }

    function test_reverts_when_name_is_already_used() public {
        vm.prank(creator);
        factory.create("constellation_A", "CA", 18, 1000);

        vm.expectRevert(IConstellation.Constellation_NameAlreadyUsed.selector);
        vm.prank(creator);
        factory.calculateDeploymentAddress(creator, "constellation_A");
    }
}

contract Factory__update is Setup, IConstellation {
    function test_update_constellation_token() public {
        factory.updateToken("Constellation", constellation, constellation);
    }

    function test_update_constellation_token_not_owner() public {
        vm.prank(creator);
        vm.expectRevert(IConstellation.Constellation_NotFoundOrNotOwner.selector);
        factory.updateToken("Constellation", constellation, constellation);
    }
}

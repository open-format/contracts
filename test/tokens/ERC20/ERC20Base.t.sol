// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ERC20BaseMock} from "../../../src/tokens/ERC20/ERC20BaseMock.sol";

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import {IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    ERC20BaseMock erc20Base;

    function setUp() public {
        vm.prank(creator);
        erc20Base = new ERC20BaseMock(
          "Name",
          "Symbol",
          18,
          10_000
        );

        afterSetUp();
    }

    // can override this function to perform further setup tasks
    function afterSetUp() public virtual {}
}

contract ERC20__initialize is Setup {
    function test_sets_owner() public {
        assertEq(erc20Base.owner(), creator);
    }

    function test_sets_name() public {
        assertEq(erc20Base.name(), "Name");
    }

    function test_sets_symbol() public {
        assertEq(erc20Base.symbol(), "Symbol");
    }

    function test_sets_decimal() public {
        assertEq(erc20Base.decimals(), 18);
    }

    function test_mints_supply_to_owner() public {
        assertEq(erc20Base.balanceOf(creator), 10_000);
    }

    function test_supports_IERC165_interfaces() public {
        assertTrue(erc20Base.supportsInterface(type(IERC165).interfaceId));
    }

    function test_supports_ERC20_interfaces() public {
        assertTrue(erc20Base.supportsInterface(type(IERC20).interfaceId));
    }

    function test_supports_IERC2612_interfaces() public {
        assertTrue(erc20Base.supportsInterface(type(IERC2612).interfaceId));
    }

    function test_supports_IContractMetadata_interfaces() public {
        assertTrue(erc20Base.supportsInterface(type(IContractMetadata).interfaceId));
    }

    function test_cannot_be_initialized_again() public {
        vm.expectRevert("Initializable: contract is already initialized");
        erc20Base.initialize(other, "Name", "Symbol", 18, 10_000);
    }
}

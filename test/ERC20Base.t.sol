// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {ERC20} from "../src/token/ERC20Base.sol";

contract test_ERC20 is Test {
    ERC20 token;
    address alice = vm.addr(0x1);
    address bob = vm.addr(0x2);
    string constant name = "NAME";
    string constant symbol = "SYMBOL";

    function setUp() public {
        token = new ERC20(name, symbol);
    }

    function test_name() public {
        assertEq(name, token.name());
    }

    function test_symbol() public {
        assertEq(symbol, token.symbol());
    }

    function test_mint() public {
        token.mint(alice, 1);
        assertEq(token.balanceOf(alice), 1);
    }

    function test_mint_as_not_owner() public {
        vm.prank(bob);
        vm.expectRevert();
        token.mint(alice, 1);
    }
}

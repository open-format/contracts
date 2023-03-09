// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ERC20BaseMock} from "../../../src/tokens/ERC20/ERC20BaseMock.sol";

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

import {IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";
import {IInitializable} from "@extensions/initializable/IInitializable.sol";

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    ERC20BaseMock erc20Base;

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string contractURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";

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
        vm.expectRevert(IInitializable.Initializable_contractIsAlreadyInitialized.selector);
        erc20Base.initialize(other, "Name", "Symbol", 18, 10_000);
    }
}

contract ERC20__mintTo is Setup {
    function test_can_mint_to_an_address() public {
        vm.prank(creator);
        erc20Base.mintTo(other, 10_000);
        assertEq(erc20Base.balanceOf(other), 10_000);
    }

    function test_reverts_if_not_the_owner() public {
        vm.prank(other);
        vm.expectRevert("Not authorized to mint.");
        erc20Base.mintTo(other, 10_000);
    }

    function test_reverts_amount_is_zero() public {
        vm.prank(creator);
        vm.expectRevert("Minting zero tokens.");
        erc20Base.mintTo(other, 0);
    }
}

contract ERC20__burn is Setup {
    function test_can_burn() public {
        vm.prank(creator);
        erc20Base.burn(10_000);
        assertEq(erc20Base.balanceOf(creator), 0);
    }

    function test_reverts_if_not_enough_balance() public {
        vm.prank(creator);
        vm.expectRevert("not enough balance");
        erc20Base.burn(10_001);
    }
}

contract ERC20Base__setContractURI is Setup {
    function test_sets_contract_uri() public {
        vm.prank(creator);
        erc20Base.setContractURI(contractURI);

        assertEq(contractURI, erc20Base.contractURI());
    }

    function test_reverts_if_not_the_owner() public {
        vm.prank(other);
        vm.expectRevert();
        erc20Base.setContractURI(contractURI);
    }
}

contract ERC20Base__multicall is Setup {
    function test_can_perfom_multiple_calls_in_one_transaction() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(erc20Base.transfer, (other, 5_000));
        calls[1] = abi.encodeCall(erc20Base.burn, (4_000));

        vm.prank(creator);
        erc20Base.multicall(calls);

        assertEq(erc20Base.balanceOf(creator), 1_000);
        assertEq(erc20Base.balanceOf(other), 5_000);
    }
}

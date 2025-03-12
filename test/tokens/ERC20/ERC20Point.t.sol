// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ERC20PointMock, ERC20Point} from "../../../src/tokens/ERC20/ERC20PointMock.sol";

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

import {IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";
import {IInitializable} from "@extensions/initializable/IInitializable.sol";

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

contract Setup is Test {
    address creator = address(0x10);
    address other = address(0x11);
    ERC20PointMock erc20Point;

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string contractURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";

    function setUp() public {
        vm.prank(creator);
        erc20Point = new ERC20PointMock(
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
    function test_sets_admin() public {
        assertTrue(erc20Point.hasRole(ADMIN_ROLE, creator));
    }

    function test_sets_name() public {
        assertEq(erc20Point.name(), "Name");
    }

    function test_sets_symbol() public {
        assertEq(erc20Point.symbol(), "Symbol");
    }

    function test_sets_decimal() public {
        assertEq(erc20Point.decimals(), 18);
    }

    function test_mints_supply_to_owner() public {
        assertEq(erc20Point.balanceOf(creator), 10_000);
    }

    function test_supports_IERC165_interfaces() public {
        assertTrue(erc20Point.supportsInterface(type(IERC165).interfaceId));
    }

    function test_supports_ERC20_interfaces() public {
        assertTrue(erc20Point.supportsInterface(type(IERC20).interfaceId));
    }

    function test_supports_IERC2612_interfaces() public {
        assertTrue(erc20Point.supportsInterface(type(IERC2612).interfaceId));
    }

    function test_supports_IContractMetadata_interfaces() public {
        assertTrue(erc20Point.supportsInterface(type(IContractMetadata).interfaceId));
    }

    function test_cannot_be_initialized_again() public {
        vm.expectRevert(IInitializable.Initializable_contractIsAlreadyInitialized.selector);
        erc20Point.initialize(other, "Name", "Symbol", 18, 10_000, "");
    }
}

contract ERC20__mintTo is Setup {
    function test_can_mint_to_an_address() public {
        vm.prank(creator);
        erc20Point.mintTo(other, 10_000);
        assertEq(erc20Point.balanceOf(other), 10_000);
    }

    function test_reverts_if_not_the_owner() public {
        vm.prank(other);
        vm.expectRevert(ERC20Point.ERC20Point_notAuthorized.selector);
        erc20Point.mintTo(other, 10_000);
    }

    function test_reverts_amount_is_zero() public {
        vm.prank(creator);
        vm.expectRevert(ERC20Point.ERC20Point_zeroAmount.selector);
        erc20Point.mintTo(other, 0);
    }
}

contract ERC20__burn is Setup {
    function test_can_burn() public {
        vm.prank(creator);
        vm.expectRevert(ERC20Point.ERC20Point_nonTransferableToken.selector);
        erc20Point.burn(10_000);
    }
}

contract ERC20__setContractURI is Setup {
    function test_sets_contract_uri() public {
        vm.prank(creator);
        erc20Point.setContractURI(contractURI);

        assertEq(contractURI, erc20Point.contractURI());
    }

    function test_reverts_if_not_the_owner() public {
        vm.prank(other);
        vm.expectRevert();
        erc20Point.setContractURI(contractURI);
    }
}

contract ERC20B__multicall is Setup {
    function test_can_perfom_multiple_calls_in_one_transaction() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeCall(erc20Point.mintTo, (other, 1_000));
        calls[1] = abi.encodeCall(erc20Point.mintTo, (other, 1_000));

        vm.prank(creator);
        erc20Point.multicall(calls);

        assertEq(erc20Point.balanceOf(other), 2_000);
    }
}

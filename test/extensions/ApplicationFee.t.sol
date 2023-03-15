// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ApplicationFeeMock, IApplicationFee} from "src/extensions/applicationFee/ApplicationFeeMock.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

import {ERC20BaseMock} from "src/tokens/ERC20/ERC20BaseMock.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

contract Setup is Test {
    address recipient;
    uint16 tenPercentBPS;
    ApplicationFeeMock applicationFee;

    function setUp() public {
        recipient = address(0x10);
        tenPercentBPS = 1000;
        applicationFee = new ApplicationFeeMock();

        _afterSetup();
    }

    function _afterSetup() internal virtual {}
}

contract ApplicationFee__applicationFeeInfo is Setup {
    function test_returns_zero_address_and_amount_when_not_set() public {
        (address recipient, uint256 amount) = applicationFee.applicationFeeInfo(100 ether);
        assertEq(recipient, address(0));
        assertEq(amount, 0);
    }

    function test_returns_percentage_of_price() public {
        applicationFee.setApplicationFee(tenPercentBPS, recipient);

        (, uint256 amount) = applicationFee.applicationFeeInfo(100 ether);
        assertEq(amount, 10 ether);
    }

    function test_returns_recipient() public {
        applicationFee.setApplicationFee(tenPercentBPS, recipient);

        (address recipient,) = applicationFee.applicationFeeInfo(100 ether);
        assertEq(recipient, recipient);
    }
}

contract ApplicationFee__internal_setApplicationFee is Setup {
    function test_sets_application_fee() public {
        applicationFee.setApplicationFee(tenPercentBPS, recipient);

        assertEq(applicationFee.percentBPS(), tenPercentBPS);
        assertEq(applicationFee.recipient(), recipient);
    }

    function test_reverts_if_percent_exceeds_100() public {
        vm.expectRevert(IApplicationFee.ApplicationFee_exceedsMaxPercentBPS.selector);
        applicationFee.setApplicationFee(10_001, recipient);
    }
}

contract ApplicationFee__internal_setAcceptedCurrencies is Setup {
    function test_sets_accepted_currencies() public {
        address[] memory currencies = new address[](3);
        currencies[0] = address(0); // native token
        currencies[1] = address(0xabc);
        currencies[2] = address(0xdef);

        bool[] memory approvals = new bool[](3);
        approvals[0] = true;
        approvals[1] = true;
        approvals[2] = true;

        applicationFee.setAcceptedCurrencies(currencies, approvals);

        assertTrue(applicationFee.isCurrencyAccepted(address(0)));
        assertTrue(applicationFee.isCurrencyAccepted(address(0xabc)));
        assertTrue(applicationFee.isCurrencyAccepted(address(0xdef)));
    }

    function test_reverts_when_currencies_and_approvals_are_different_length() public {
        address[] memory currencies = new address[](1);
        currencies[0] = address(0); // native token

        bool[] memory approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = true;

        vm.expectRevert(IApplicationFee.ApplicationFee_currenciesAndApprovalsMustBeTheSameLength.selector);
        applicationFee.setAcceptedCurrencies(currencies, approvals);
    }
}

contract ApplicationFee__internal_payApplicationFee is Setup {
    ERC20BaseMock erc20;

    event PaidApplicationFee(address currency, uint256 amount);

    function _afterSetup() internal override {
        applicationFee.setApplicationFee(tenPercentBPS, recipient);

        // create Dummy ERC20 token
        erc20 = new ERC20BaseMock("Dummy", "D", 18, 1000);

        // accept native token
        address[] memory currencies = new address[](2);
        currencies[0] = address(0); // native token
        currencies[1] = address(erc20);

        bool[] memory approvals = new bool[](2);
        approvals[0] = true;
        approvals[1] = true;

        applicationFee.setAcceptedCurrencies(currencies, approvals);
    }

    function test_pays_application_fee() public {
        erc20.approve(address(applicationFee), 100);

        applicationFee.payApplicationFee(address(erc20), 100);

        assertEq(erc20.balanceOf(recipient), 10);
    }

    function test_pays_application_fee_with_native_token() public {
        applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(recipient.balance, 10 ether);
    }

    function test_returns_remaining_amount() public {
        erc20.approve(address(applicationFee), 100);
        uint256 remaining = applicationFee.payApplicationFee(address(erc20), 100);

        assertEq(remaining, 90);
    }

    function test_returns_remaining_amount_with_native_token() public {
        uint256 remaining = applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(remaining, 90 ether);
    }

    function test_returns_full_price_if_no_fee() public {
        applicationFee.setApplicationFee(0, recipient);

        erc20.approve(address(applicationFee), 100);
        uint256 remaining = applicationFee.payApplicationFee(address(erc20), 100);

        assertEq(remaining, 100);
    }

    function test_returns_full_price_if_no_fee_with_native_token() public {
        applicationFee.setApplicationFee(0, recipient);
        uint256 remaining = applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(remaining, 100 ether);
    }

    function test_reverts_if_currency_not_accepted() public {
        vm.expectRevert(IApplicationFee.ApplicationFee_currencyNotAccepted.selector);
        applicationFee.payApplicationFee(address(0xabc), 100);
    }

    function test_emits_paidApplicationFee_event() public {
        erc20.approve(address(applicationFee), 100);
        vm.expectEmit(true, true, true, true);
        emit PaidApplicationFee(address(erc20), 10);
        applicationFee.payApplicationFee(address(erc20), 100);
    }

    function test_emits_paidApplicationFee_event_with_native_token() public {
        vm.expectEmit(true, true, true, true);
        emit PaidApplicationFee(address(0), 10 ether);
        applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);
    }

    function test_reverts_if_msg_value_less_than_fee_with_native_token() public {
        vm.expectRevert(CurrencyTransferLib.CurrencyTransferLib_insufficientValue.selector);
        applicationFee.payApplicationFee{value: 9 ether}(address(0), 100 ether);
    }
}

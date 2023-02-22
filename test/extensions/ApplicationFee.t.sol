// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {ApplicationFeeMock, IApplicationFee} from "src/extensions/applicationFee/ApplicationFeeMock.sol";

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
}

contract ApplicationFee__internal_setAcceptedTokens is Setup {
    function test_sets_accepted_tokens() public {
        address[] memory tokens = new address[](3);
        tokens[0] = address(0); // native token
        tokens[1] = address(0xabc);
        tokens[2] = address(0xdef);

        bool[] memory approvals = new bool[](3);
        approvals[0] = true;
        approvals[1] = true;
        approvals[2] = true;

        applicationFee.setAcceptedTokens(tokens, approvals);

        assertTrue(applicationFee.isTokenAccepted(address(0)));
        assertTrue(applicationFee.isTokenAccepted(address(0xabc)));
        assertTrue(applicationFee.isTokenAccepted(address(0xdef)));
    }
}

contract ApplicationFee__internal_payApplicationFee is Setup, IApplicationFee {
    function _afterSetup() internal override {
        applicationFee.setApplicationFee(tenPercentBPS, recipient);
        // accept native token
        address[] memory tokens = new address[](1);
        tokens[0] = address(0); // native token
        //TODO: add dummy ERC20

        bool[] memory approvals = new bool[](1);
        approvals[0] = true;

        applicationFee.setAcceptedTokens(tokens, approvals);
    }

    function test_pays_native_token() public {
        applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(recipient.balance, 10 ether);
    }

    function test_returns_remaining_amount() public {
        uint256 remaining = applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(remaining, 90 ether);
    }

    function test_returns_full_price_if_no_fee() public {
        applicationFee.setApplicationFee(0, recipient);
        uint256 remaining = applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(remaining, 100 ether);
    }

    function test_reverts_if_token_not_accepted() public {
        vm.expectRevert("currency not accepted");
        applicationFee.payApplicationFee(address(0xabc), 100 ether);
    }

    function test_emits_paidApplicationFee_event_paying_with_native_token() public {
        vm.expectEmit(true, true, true, true);
        emit PaidApplicationFee(address(0), 10 ether);
        applicationFee.payApplicationFee{value: 100 ether}(address(0), 100 ether);

        assertEq(recipient.balance, 10 ether);
    }

    function test_reverts_if_msg_value_less_than_native_token_fee() public {
        vm.expectRevert(IApplicationFee.Error_insufficientValue.selector);
        uint256 remaining = applicationFee.payApplicationFee{value: 9 ether}(address(0), 100 ether);
    }

    // TODO: test_pays_token
}

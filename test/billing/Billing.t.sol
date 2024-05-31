// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {Billing} from "src/billing/Billing.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {Governed} from "src/extensions/governed/Governed.sol";

contract OftToken is SolidStateERC20, Ownable {
    constructor(uint256 _initialSupply) {
        _setOwner(msg.sender);
        _setName("OFT Token");
        _setSymbol("OFT");
        _setDecimals(18);

        _mint(msg.sender, _initialSupply);
    }
    function mint(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }
}

contract AppOwnableMock is Ownable {
    constructor(address _appOwner) {
        _setOwner(_appOwner);
    }
}

contract Setup is Test {
    address collector = address(0x10);
    address governor = address(0x11);
    address user1 = address(0x12);
    OftToken oftToken;
    Billing billing;

    function setUp() public {
        vm.startPrank(governor);
        oftToken = new OftToken(10000);
        billing = new Billing(collector, address(oftToken), governor, false); 
        oftToken.mint(user1, 1000);
        vm.stopPrank();

        vm.startPrank(user1);
        oftToken.increaseAllowance(address(billing), 1000000000);
        vm.stopPrank();
        
        afterSetUp();
    }

    // can override this function to perform further setup tasks
    function afterSetUp() public virtual {}
}

contract Billing__governed is Setup {
    event NewPendingOwnership(address indexed from, address indexed to);
    event NewOwnership(address indexed from, address indexed to);

    function test_revert_governor_zero() public {
        OftToken oftToken = new OftToken(10000);
        vm.expectRevert(Governed.Governed_invalidGovernorAddress.selector);
        billing = new Billing(collector, address(oftToken), address(0), false); 
    }

    function test_revert_transfer_not_governor() public {
        vm.prank(collector);
        vm.expectRevert(Governed.Governed_notAuthorised.selector);
        billing.transferOwnership(collector);
    }

    function test_revert_transfer_zero_addr() public {
        vm.prank(governor);
        vm.expectRevert(Governed.Governed_invalidGovernorAddress.selector);
        billing.transferOwnership(address(0));
    }

    function test_transfer_and_accept_ok() public {
        // transfer
        vm.startPrank(governor);

        vm.expectEmit(false, true, true, true);
        emit NewPendingOwnership(governor, collector);
        billing.transferOwnership(collector);
        
        vm.stopPrank();

        // accept
        vm.startPrank(collector);

        vm.expectEmit(false, true, true, true);
        emit NewOwnership(governor, collector);
        billing.acceptOwnership();
        
        vm.stopPrank();

    }
}

contract Billing__all is Setup {
    function test_add_collector() public { }
    function test_remove_collector() public { }

    function test_deposit_invalid_amount() public {
        vm.prank(user1);
        vm.expectRevert(Billing.Billing_zeroAmount.selector);
        billing.deposit(address(0x1), 0);
        assertTrue(billing.getBalance(address(0x1)) == 0);
    }
    function test_deposit_invalid_app() public {
        vm.prank(user1);
        vm.expectRevert(Billing.Billing_invalidAppAddress.selector);
        billing.deposit(address(0), 1);
    }
    function test_deposit_ok() public {
        vm.prank(user1);
        billing.deposit(address(0x11), 1);
        assertTrue(billing.getBalance(address(0x11)) == 1);
    }
    function test_deposit_to_many_different_lengths() public {
        address[] memory apps = new address[](2);
        apps[0] = address(0x1);
        apps[1] = address(0x2);
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.prank(user1);
        vm.expectRevert(Billing.Billing_appsAndAmountssMustBeTheSameLength.selector);
        billing.depositToMany(apps, amounts);
        assertTrue(billing.getBalance(address(0x1)) == 0);
        assertTrue(billing.getBalance(address(0x2)) == 0);
    }
    function test_deposit_to_many_invalid_amount() public { 
        address[] memory apps = new address[](2);
        apps[0] = address(0x1);
        apps[1] = address(0x2);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[0] = 0;
        
        vm.prank(user1);
        vm.expectRevert(Billing.Billing_zeroAmount.selector);
        billing.depositToMany(apps, amounts);
        assertTrue(billing.getBalance(address(0x1)) == 0);
        assertTrue(billing.getBalance(address(0x2)) == 0);
    }
    function test_deposit_to_many_invalid_app() public {
        address[] memory apps = new address[](2);
        apps[0] = address(0x1);
        apps[1] = address(0);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;
        
        vm.prank(user1);
        vm.expectRevert(Billing.Billing_invalidAppAddress.selector);
        billing.depositToMany(apps, amounts);
        assertTrue(billing.getBalance(address(0x1)) == 0);
    }
    function test_deposit_to_many_ok() public {
        address[] memory apps = new address[](2);
        apps[0] = address(0x1);
        apps[1] = address(0x2);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;
        
        vm.startPrank(user1);
        billing.depositToMany(apps, amounts);

        assertTrue(billing.getBalance(address(0x1)) == 1);
        assertTrue(billing.getBalance(address(0x2)) == 2);
        vm.stopPrank();
     }
    
    function test_withdraw_invalid_app() public { 
        vm.prank(user1);
        vm.expectRevert(Billing.Billing_invalidAppAddress.selector);
        billing.withdraw(address(0), 1);
    }
    function test_withdraw_invalid_not_owner() public {
        vm.startPrank(user1);
        AppOwnableMock appMock = new AppOwnableMock(address(0x14));
        vm.expectRevert(Billing.Billing_notAuthorised.selector);
        billing.withdraw(address(appMock), 1);
        vm.stopPrank();
    }
    function test_withdraw_invalid_amount() public {
        address ownerAddress = address(0x14);
        vm.startPrank(ownerAddress);
        AppOwnableMock appMock = new AppOwnableMock(ownerAddress);
        vm.expectRevert(Billing.Billing_zeroAmount.selector);
        billing.withdraw(address(appMock), 0);
        vm.stopPrank();
    }
    function test_withdraw_insufficient_balance() public {
        address ownerAddress = address(0x14);
        vm.startPrank(ownerAddress);
        AppOwnableMock appMock = new AppOwnableMock(ownerAddress);
        vm.expectRevert(Billing.Billing_insufficientBalance.selector);
        billing.withdraw(address(appMock), 1_000_000);
        vm.stopPrank();
    }
    function test_withdraw_ok() public {
        address ownerAddress = address(0x14);

        vm.startPrank(ownerAddress);
        AppOwnableMock appMock = new AppOwnableMock(ownerAddress);
        vm.stopPrank();
        
        vm.startPrank(user1);
        billing.deposit(address(appMock), 1);        
        assertTrue(billing.getBalance(address(appMock)) == 1);
        vm.stopPrank();

        vm.startPrank(ownerAddress);
        uint256 balance = oftToken.balanceOf(ownerAddress);
        billing.withdraw(address(appMock), 1);
        assertTrue(billing.getBalance(address(appMock)) == 0);
        assertTrue(oftToken.balanceOf(ownerAddress) == balance + 1);
        vm.stopPrank();
    }

    function test_create_bill_only_collector() public {
        vm.prank(user1);
        vm.expectRevert(Billing.Billing_notAuthorised.selector);
        billing.createBill(address(0x222), 1, 1);
    }
    function test_create_bill_invalid_app() public {
        vm.prank(collector);
        vm.expectRevert(Billing.Billing_invalidAppAddress.selector);
        billing.createBill(address(0), 1, 1);
    }
    function test_create_bill_invalid_amount() public {
        vm.prank(collector);
        vm.expectRevert(Billing.Billing_zeroAmount.selector);
        billing.createBill(address(0x222), 0, 1);
    }
    function test_create_bill_invalid_deadline() public {
        vm.prank(collector);
        vm.warp(1000000001);
        vm.expectRevert(Billing.Billing_invalidDeadline.selector);
        billing.createBill(address(0x222), 1, 1000000000);
    }
    function test_create_bill_ok() public {
        uint256 amount = 1;
        uint256 deadline = 1000000001;
        vm.prank(collector);
        vm.warp(deadline - 1);
        billing.createBill(address(0x222), amount, deadline);
        (uint256 billAmount, uint256 billDeadline) = billing.getBill(address(0x222));
        assertTrue(amount == billAmount);
        assertTrue(deadline == billDeadline);
    }

    function test_create_bill_to_many_only_collector() public {
        address[] memory apps = new address[](1);
        apps[0] = address(0x333);
        
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        uint256[] memory deadlines = new uint256[](1);
        deadlines[0] = 1000000001;
        
        vm.startPrank(user1);
        vm.warp(1000000000);
        vm.expectRevert(Billing.Billing_notAuthorised.selector);
        billing.createBillToMany(apps, amounts, deadlines);
    }
    function test_create_bill_to_many_invalid_app() public {
        address[] memory apps = new address[](2);
        apps[0] = address(0x333);
        apps[1] = address(0);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = 1000000001;
        deadlines[1] = 1000000001;
        
        vm.startPrank(collector);
        vm.warp(1000000000);
        vm.expectRevert(Billing.Billing_invalidAppAddress.selector);
        billing.createBillToMany(apps, amounts, deadlines);
    }
    function test_create_bill_to_many_invalid_amount() public {
        address[] memory apps = new address[](2);
        apps[0] = address(0x333);
        apps[1] = address(0x444);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 0;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = 1000000001;
        deadlines[1] = 1000000001;
        
        vm.startPrank(collector);
        vm.warp(1000000000);
        vm.expectRevert(Billing.Billing_zeroAmount.selector);
        billing.createBillToMany(apps, amounts, deadlines);
    }
    function test_create_bill_to_many_invalid_deadline() public {
        address[] memory apps = new address[](2);
        apps[0] = address(0x333);
        apps[1] = address(0x444);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = 1000000001;
        deadlines[1] = 1000000000;
        
        vm.startPrank(collector);
        vm.warp(1000000000);
        vm.expectRevert(Billing.Billing_invalidDeadline.selector);
        billing.createBillToMany(apps, amounts, deadlines);
    }
    function test_create_bill_to_many_ok() public {
        uint256 amount1 = 1;
        uint256 amount2 = 2;
        uint256 deadline1 = 1000000001;
        uint256 deadline2 = 1000000002;

        address[] memory apps = new address[](2);
        apps[0] = address(0x333);
        apps[1] = address(0x444);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amount1;
        amounts[1] = amount2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline1;
        deadlines[1] = deadline2;
        
        vm.startPrank(collector);
        vm.warp(1000000000);
        billing.createBillToMany(apps, amounts, deadlines);

        (uint256 billAmount1, uint256 billDeadline1) = billing.getBill(address(0x333));
        (uint256 billAmount2, uint256 billDeadline2) = billing.getBill(address(0x444));

        assertTrue(amount1 == billAmount1);
        assertTrue(deadline1 == billDeadline1);

        assertTrue(amount2 == billAmount2);
        assertTrue(deadline2 == billDeadline2);

        vm.stopPrank();
    }

    function test_deposit_pays_bills() public {
        address appAddress = address(0x1551);
        uint256 amount = 1;
        uint256 deadline = 1000000001;

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBill(appAddress, amount, deadline);
        vm.stopPrank();

        vm.startPrank(user1);
        billing.deposit(appAddress, amount);
        vm.stopPrank();
        
        // Bill amount -> 0, PaidTokens -> +amount
        vm.startPrank(collector);
        (uint256 billAmount, ) = billing.getBill(appAddress);
        assertEq(billAmount, 0);
        assertEq(billing.getBalance(appAddress), 0);
        assertEq(billing.paidTokensAmount(), paidTokens + amount);
        vm.stopPrank();
    }
    function test_deposit_pays_bills_balance_left() public {
        address appAddress = address(0x2552);
        uint256 amount = 1;
        uint256 balance = amount + 1;
        uint256 deadline = 1000000001;

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBill(appAddress, amount, deadline);
        vm.stopPrank();

        vm.startPrank(user1);
        billing.deposit(appAddress, balance);
        vm.stopPrank();
        
        vm.startPrank(collector);
        (uint256 billAmount, ) = billing.getBill(appAddress);
        assertEq(billAmount, 0);
        assertEq(billing.paidTokensAmount(), paidTokens + amount);
        assertEq(billing.getBalance(appAddress), balance - amount);
        vm.stopPrank();
    }
    function test_deposit_pays_bills_amount_left() public {
        address appAddress = address(0x3553);
        uint256 amount = 2;
        uint256 balance = amount - 1;
        uint256 deadline = 1000000001;

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBill(appAddress, amount, deadline);
        vm.stopPrank();

        vm.startPrank(user1);
        billing.deposit(appAddress, balance);
        vm.stopPrank();
        
        vm.startPrank(collector);
        (uint256 billAmount, ) = billing.getBill(appAddress);
        assertEq(billAmount, amount - balance);
        assertEq(billing.paidTokensAmount(), paidTokens + balance);
        assertEq(billing.getBalance(appAddress), 0);
        vm.stopPrank();
    }

    function test_create_bill_pays_bill() public {
        address appAddress = address(0x5555);
        uint256 amount = 1;
        uint256 deadline = 1000000001;

        vm.startPrank(user1);
        billing.deposit(appAddress, amount);
        vm.stopPrank();

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBill(appAddress, amount, deadline);
        vm.stopPrank();
        
        vm.startPrank(collector);
        (uint256 billAmount, ) = billing.getBill(appAddress);
        assertEq(billAmount, 0);
        assertEq(billing.paidTokensAmount(), paidTokens + amount);
        vm.stopPrank();
    }
    function test_create_bill_pays_balance_left() public {
        address appAddress = address(0x2662);
        uint256 amount = 1;
        uint256 balance = amount + 1;
        uint256 deadline = 1000000001;

        vm.startPrank(user1);
        billing.deposit(appAddress, balance);
        vm.stopPrank();

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBill(appAddress, amount, deadline);
        vm.stopPrank();
        
        vm.startPrank(collector);
        (uint256 billAmount, ) = billing.getBill(appAddress);
        assertEq(billAmount, 0);
        assertEq(billing.paidTokensAmount(), paidTokens + amount);
        assertEq(billing.getBalance(appAddress), balance - amount);
        vm.stopPrank();
    }
    function test_create_bill_pays_amount_left() public {
        address appAddress = address(0x3663);
        uint256 amount = 2;
        uint256 balance = amount - 1;
        uint256 deadline = 1000000001;

        vm.startPrank(user1);
        billing.deposit(appAddress, balance);
        vm.stopPrank();

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBill(appAddress, amount, deadline);
        vm.stopPrank();
        
        vm.startPrank(collector);
        (uint256 billAmount, ) = billing.getBill(appAddress);
        assertEq(billAmount, amount - balance);
        assertEq(billing.paidTokensAmount(), paidTokens + balance);
        assertEq(billing.getBalance(appAddress), 0);
        vm.stopPrank();
    }

    function test_deposit_to_many_pays_bills() public {
        address app1 = address(0x1771);
        address app2 = address(0x2772);
        uint256 deadline = 1000000001;

        address[] memory apps = new address[](2);
        apps[0] = app1;
        apps[1] = app2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline;
        deadlines[1] = deadline;

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBillToMany(apps, amounts, deadlines);
        vm.stopPrank();
        
        vm.startPrank(user1);
        billing.depositToMany(apps, amounts);
        vm.stopPrank();

        vm.startPrank(collector);
        (uint256 billAmount0, ) = billing.getBill(apps[0]);
        (uint256 billAmount1, ) = billing.getBill(apps[1]);

        assertEq(billAmount0, 0);
        assertEq(billing.getBalance(apps[0]), 0);
        assertEq(billAmount1, 0);
        assertEq(billing.getBalance(apps[1]), 0);
        
        assertEq(billing.paidTokensAmount(), paidTokens + amounts[0] + amounts[1]);
        vm.stopPrank();
    }
    function test_deposit_to_many_pays_bills_balance_left() public {
        address app1 = address(0x3773);
        address app2 = address(0x4774);
        uint256 deadline = 1000000001;

        address[] memory apps = new address[](2);
        apps[0] = app1;
        apps[1] = app2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        uint256[] memory balances = new uint256[](2);
        balances[0] = amounts[0] + 1;
        balances[1] = amounts[1] + 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline;
        deadlines[1] = deadline;

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBillToMany(apps, amounts, deadlines);
        vm.stopPrank();
        
        vm.startPrank(user1);
        billing.depositToMany(apps, balances);
        vm.stopPrank();

        vm.startPrank(collector);
        (uint256 billAmount0, ) = billing.getBill(apps[0]);
        (uint256 billAmount1, ) = billing.getBill(apps[1]);

        assertEq(billAmount0, 0);
        assertEq(billing.getBalance(apps[0]), balances[0] - amounts[0]);
        assertEq(billAmount1, 0);
        assertEq(billing.getBalance(apps[1]), balances[1] - amounts[1]);
        
        assertEq(billing.paidTokensAmount(), paidTokens + amounts[0] + amounts[1]);
        vm.stopPrank();
    }
    function test_deposit_to_many_pays_bills_amount_left() public {
        address app1 = address(0x3773);
        address app2 = address(0x4774);
        uint256 deadline = 1000000001;

        address[] memory apps = new address[](2);
        apps[0] = app1;
        apps[1] = app2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 4;

        uint256[] memory balances = new uint256[](2);
        balances[0] = amounts[0] - 1;
        balances[1] = amounts[1] - 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline;
        deadlines[1] = deadline;

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBillToMany(apps, amounts, deadlines);
        vm.stopPrank();
        
        vm.startPrank(user1);
        billing.depositToMany(apps, balances);
        vm.stopPrank();

        vm.startPrank(collector);
        (uint256 billAmount0, ) = billing.getBill(apps[0]);
        (uint256 billAmount1, ) = billing.getBill(apps[1]);

        assertEq(billAmount0, amounts[0] - balances[0]);
        assertEq(billing.getBalance(apps[0]), 0);
        assertEq(billAmount1, amounts[1] - balances[1]);
        assertEq(billing.getBalance(apps[1]), 0);
        
        assertEq(billing.paidTokensAmount(), paidTokens + balances[0] + balances[1]);
        vm.stopPrank();
    }

    function test_create_bill_to_many_pays_bill() public {
        address app1 = address(0x1771);
        address app2 = address(0x2772);
        uint256 deadline = 1000000001;

        address[] memory apps = new address[](2);
        apps[0] = app1;
        apps[1] = app2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline;
        deadlines[1] = deadline;
        
        vm.startPrank(user1);
        billing.depositToMany(apps, amounts);
        vm.stopPrank();

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBillToMany(apps, amounts, deadlines);
        vm.stopPrank();

        vm.startPrank(collector);
        (uint256 billAmount0, ) = billing.getBill(apps[0]);
        (uint256 billAmount1, ) = billing.getBill(apps[1]);

        assertEq(billAmount0, 0);
        assertEq(billing.getBalance(apps[0]), 0);
        assertEq(billAmount1, 0);
        assertEq(billing.getBalance(apps[1]), 0);
        
        assertEq(billing.paidTokensAmount(), paidTokens + amounts[0] + amounts[1]);
        vm.stopPrank();
    }
    function test_create_bill_to_many_pays_bill_balance_left() public {
        address app1 = address(0x3773);
        address app2 = address(0x4774);
        uint256 deadline = 1000000001;

        address[] memory apps = new address[](2);
        apps[0] = app1;
        apps[1] = app2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 2;

        uint256[] memory balances = new uint256[](2);
        balances[0] = amounts[0] + 1;
        balances[1] = amounts[1] + 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline;
        deadlines[1] = deadline;
        
        vm.startPrank(user1);
        billing.depositToMany(apps, balances);
        vm.stopPrank();

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBillToMany(apps, amounts, deadlines);
        vm.stopPrank();

        vm.startPrank(collector);
        (uint256 billAmount0, ) = billing.getBill(apps[0]);
        (uint256 billAmount1, ) = billing.getBill(apps[1]);

        assertEq(billAmount0, 0);
        assertEq(billing.getBalance(apps[0]), balances[0] - amounts[0]);
        assertEq(billAmount1, 0);
        assertEq(billing.getBalance(apps[1]), balances[1] - amounts[1]);
        
        assertEq(billing.paidTokensAmount(), paidTokens + amounts[0] + amounts[1]);
        vm.stopPrank();
    }
    function test_create_bill_to_many_pays_bill_amount_left() public {
        address app1 = address(0x3773);
        address app2 = address(0x4774);
        uint256 deadline = 1000000001;

        address[] memory apps = new address[](2);
        apps[0] = app1;
        apps[1] = app2;
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 2;
        amounts[1] = 4;

        uint256[] memory balances = new uint256[](2);
        balances[0] = amounts[0] - 1;
        balances[1] = amounts[1] - 2;

        uint256[] memory deadlines = new uint256[](2);
        deadlines[0] = deadline;
        deadlines[1] = deadline;
        
        vm.startPrank(user1);
        billing.depositToMany(apps, balances);
        vm.stopPrank();

        vm.startPrank(collector);
        vm.warp(deadline - 1);
        uint256 paidTokens = billing.paidTokensAmount();
        billing.createBillToMany(apps, amounts, deadlines);
        vm.stopPrank();

        vm.startPrank(collector);
        (uint256 billAmount0, ) = billing.getBill(apps[0]);
        (uint256 billAmount1, ) = billing.getBill(apps[1]);

        assertEq(billAmount0, amounts[0] - balances[0]);
        assertEq(billing.getBalance(apps[0]), 0);
        assertEq(billAmount1, amounts[1] - balances[1]);
        assertEq(billing.getBalance(apps[1]), 0);
        
        assertEq(billing.paidTokensAmount(), paidTokens + balances[0] + balances[1]);
        vm.stopPrank();
    }
    
    function test_get_token_ok() public {
        assertEq(address(oftToken), billing.getToken());       
    }
    function test_set_token_not_updatable() public {
        vm.prank(governor);
        vm.expectRevert(Billing.Billing_tokenUpdateNotAllowed.selector);
        billing.setToken(address(0x123456));
    }
    function test_set_token_invalid_address() public {
        vm.startPrank(governor);
        Billing billingUpdatable = new Billing(collector, address(oftToken), governor, true); 
        vm.expectRevert(Billing.Billing_invalidTokenAddress.selector);
        billingUpdatable.setToken(address(0));
        vm.stopPrank();
    }
    function test_set_token_ok() public {
        address newToken = address(0x7777);
        vm.startPrank(governor);
        Billing billingUpdatable = new Billing(collector, address(oftToken), governor, true); 
        assertEq(address(oftToken), billingUpdatable.getToken());
        billingUpdatable.setToken(newToken);
        assertEq(newToken, billingUpdatable.getToken());
        vm.stopPrank();
    }

    // function test_() public { }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that the platform fee extension works as intentended within the ecosystem

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {AppFactory} from "src/factories/App.sol";
import {Globals} from "src/globals/Globals.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {BillingChecker} from "src/extensions/billingChecker/BillingChecker.sol";
import {IBillingChecker} from "src/extensions/billingChecker/IBillingChecker.sol";
import {Billing} from "src/billing/Billing.sol";

contract PaidMessageFacet is BillingChecker {
    error PaidMessageFacet_notPaid();
    
    string public message = "";

    function write(string memory _message) external {
        if (!_hasPaid(address(this))) {
            revert PaidMessageFacet_notPaid();
        }
        message = _message;
    }

    function read() external view returns (string memory) {
        return message;
    }
}

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

abstract contract Helpers {
    function prepareSingleFacetCut(
        address cutAddress,
        IDiamondWritableInternal.FacetCutAction cutAction,
        bytes4[] memory selectors
    ) public pure returns (IDiamondWritableInternal.FacetCut[] memory) {
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(cutAddress, cutAction, selectors);
        return cuts;
    }
}

contract Setup is Test, Helpers {
    address creator;
    address socialConscious;
    address billingCollector;
    address billingGovernor;
    address billingPayer;

    AppFactory appFactory;
    Proxy template;
    Proxy app;
    RegistryMock registry;
    PaidMessageFacet facet;
    Globals globals;
    ERC20Base erc20Implementation;
    
    OftToken oftToken;
    Billing billing;

    function setUp() public {
        creator = address(0x10);
        socialConscious = address(0x11);

        globals = new Globals();
        registry = new RegistryMock();
        template = new  Proxy(true);
        appFactory = new AppFactory(address(template), address(registry), address(globals));
        facet = new PaidMessageFacet();

        erc20Implementation = new ERC20Base();

        // add facet to registry
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = PaidMessageFacet.write.selector;
        selectors[1] = PaidMessageFacet.read.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(facet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );

        // Billing
        billingCollector = address(0x21);
        billingGovernor = address(0x22);
        billingPayer = address(0x23);

        vm.startPrank(billingGovernor);
        oftToken = new OftToken(10000);
        billing = new Billing(billingCollector, address(oftToken), billingGovernor, false); 
        oftToken.mint(billingPayer, 1000);
        vm.stopPrank();

        vm.startPrank(billingPayer);
        oftToken.increaseAllowance(address(billing), 1000000000);
        vm.stopPrank();

        // Configure billing in Globals
        globals.setBillingContract(address(billing));

        // create app
        app = Proxy(payable(appFactory.create("billingCheckerTest", address(0))));
    }
}

contract BillingChecker__intergration is Setup {
    function test_app_has_paid_true() public {
        uint256 amount = 1;
        uint256 deadline = 1000000001;

        vm.startPrank(billingPayer);
        PaidMessageFacet(address(app)).write("no_bill");
        assertEq(PaidMessageFacet(address(app)).read(), "no_bill");
        vm.stopPrank();
        
        vm.startPrank(billingCollector);
        vm.warp(deadline - 5);
        billing.createBill(address(app), amount, deadline);
        PaidMessageFacet(address(app)).write("bill_not_expired");
        assertEq(PaidMessageFacet(address(app)).read(), "bill_not_expired");
        vm.stopPrank();

        vm.startPrank(billingPayer);
        billing.deposit(address(app), amount);
        PaidMessageFacet(address(app)).write("paid_bill");
        assertEq(PaidMessageFacet(address(app)).read(), "paid_bill");
        vm.stopPrank();
    }
    function test_app_has_paid_false() public {
        uint256 amount = 1;
        uint256 deadline = 1000000001;

        vm.startPrank(billingCollector);
        vm.warp(deadline - 5);
        billing.createBill(address(app), amount, deadline);
        vm.stopPrank();

        vm.startPrank(billingPayer);
        vm.warp(deadline + 5);
        vm.expectRevert(PaidMessageFacet.PaidMessageFacet_notPaid.selector);
        PaidMessageFacet(address(app)).write("unpaid_expired_bill");
        vm.stopPrank();

        vm.startPrank(billingPayer);
        billing.deposit(address(app), amount);
        PaidMessageFacet(address(app)).write("paid_bill");
        assertEq(PaidMessageFacet(address(app)).read(), "paid_bill");
        vm.stopPrank();
    }
}

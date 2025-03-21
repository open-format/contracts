// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests ERC20Point integration with Globals ERC20FactoryFacet and platform fees

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {AppFactory} from "src/factories/App.sol";
import {Globals} from "src/globals/Globals.sol";

import {ERC20Point, ADMIN_ROLE, MINTER_ROLE} from "src/tokens/ERC20/ERC20Point.sol";
import {IERC20Factory} from "@extensions/ERC20Factory/IERC20Factory.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";
import {SettingsFacet, IApplicationAccess} from "src/facet/SettingsFacet.sol";

import {Deploy} from "scripts/core/Globals.s.sol";

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

/**
 * @dev dummy contract to test platform fee is not paid when called from a contract
 *      must first grant MINTER_ROLE to this contract
 */

contract MinterDummy {
    function mintTo(address _erc20, address _account, uint256 _amount) public {
        ERC20Point(_erc20).mintTo(_account, _amount);
    }
}

contract Setup is Test, Helpers {
    address creator;
    address other;
    address socialConscious;

    AppFactory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;

    ERC20Point erc20Implementation;
    bytes32 erc20ImplementationId;
    ERC20FactoryFacet erc20FactoryFacet;

    function setUp() public {
        // assign addresses
        creator = address(0x10);
        other = address(0x11);
        socialConscious = address(0x12);

        vm.deal(creator, 1 ether);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new  Proxy(true);
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        erc20Implementation = new ERC20Point();
        erc20ImplementationId = bytes32("Point");
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("platformFeeTest", creator)));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC20Implementation(erc20ImplementationId, address(erc20Implementation));

        settingsFacet = new SettingsFacet();
        {
            // add SettingsFacet to registry
            bytes4[] memory selectors = new bytes4[](1);
            selectors[0] = settingsFacet.setCreatorAccess.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        {
            // add erc20FactoryFacet to registry
            bytes4[] memory selectors = new bytes4[](3);
            selectors[0] = erc20FactoryFacet.createERC20.selector;
            selectors[1] = erc20FactoryFacet.getERC20FactoryImplementation.selector;
            selectors[2] = erc20FactoryFacet.calculateERC20FactoryDeploymentAddress.selector;
            registry.diamondCut(
                prepareSingleFacetCut(
                    address(erc20FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
                ),
                address(0),
                ""
            );
        }

        _afterSetup();
    }

    /**
     * @dev override to add more setup per test contract
     */
    function _afterSetup() internal virtual {}
}

contract ERC20Point_Setup is Setup {
    ERC20Point point;
    MinterDummy minter;

    function _afterSetup() internal override {
        ERC20Point pointImplementation = new ERC20Point();
        bytes32 pointImplementationId = bytes32("Point");
        globals.setERC20Implementation(pointImplementationId, address(pointImplementation));

        // create lazy mint erc20
        vm.prank(creator);
        // forgefmt: disable-start
        point = ERC20Point(
            ERC20FactoryFacet(address(app)).createERC20(
                "name",
                "symbol",
                18,
                0,
                pointImplementationId
            )
        );
        // forgefmt: disable-end

        // create contract that can mint
        minter = new MinterDummy();
        // grant minter role to minter contract
        vm.prank(creator);
        point.grantRole(MINTER_ROLE, address(minter));
    }
}

contract ERC20Point__integration_mintTo is ERC20Point_Setup {
    function test_mints_nft() public {
        vm.prank(creator);
        point.mintTo(creator, 1000);

        // check nft is minted to creator
        assertEq(point.balanceOf(creator), 1000);
    }

    function test_pays_platform_fee() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.prank(creator);
        point.mintTo{value: basePlatformFee}(creator, 1000);

        // check platform fee has been received
        assertEq(socialConscious.balance, basePlatformFee);
    }

    function test_does_not_pay_platform_fee_when_called_from_contract() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        minter.mintTo(address(point), creator, 1000);
        assertEq(point.balanceOf(creator), 1000);
    }
}

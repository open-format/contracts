// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that the platform fee extension works as intentended within the ecosystem

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

import {IERC20Factory} from "@extensions/ERC20Factory/IERC20Factory.sol";
import {ERC20Base, ADMIN_ROLE, MINTER_ROLE} from "src/tokens/ERC20/ERC20Base.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";

import {SettingsFacet, IApplicationAccess} from "src/facet/SettingsFacet.sol";

// bad erc20 implementation without an initialize function
contract BadERC20 {}

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
    address other;
    address socialConscious;

    AppFactory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    SettingsFacet settingsFacet;

    ERC20Base erc20Implementation;
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

        erc20Implementation = new ERC20Base();
        erc20ImplementationId = bytes32("base");
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("ERC721LazyMintTest", creator)));

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
            // add facet to registry
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
    }
}

contract ERC20FactoryFacet__integration_createERC20 is Setup {
    event Created(
        address id,
        address creator,
        string name,
        string symbol,
        uint8 decimals,
        uint256 supply,
        bytes32 implementationId
    );

    // to check contracts deployed to same address
    mapping(address => bool) deployments;

    function test_can_create_erc20() public {
        vm.prank(creator);
        address erc20Address =
            ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);

        assertEq(ERC20Base(erc20Address).name(), "name");
        assertEq(ERC20Base(erc20Address).symbol(), "symbol");
        assertEq(ERC20Base(erc20Address).decimals(), 18);
        assertEq(ERC20Base(erc20Address).totalSupply(), 1000);
        assertEq(ERC20Base(erc20Address).balanceOf(creator), 1000);

        assertTrue(ERC20Base(erc20Address).hasRole(ADMIN_ROLE, creator));
        assertTrue(ERC20Base(erc20Address).hasRole(MINTER_ROLE, address(app)));
    }

    function test_can_create_multiple_erc20_contracts() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(creator);
            address deployed =
                ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
            if (deployments[deployed] == true) {
                revert("ERC20 deployed to the same address");
            }

            deployments[deployed] = true;
        }
    }

    function test_can_create_erc721_when_approved_creator() public {
        _approveCreatorAccess(other);

        vm.prank(other);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
    }

    function test_can_create_erc721_when_zero_address_approved_creator() public {
        _approveCreatorAccess(address(0));

        vm.prank(other);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
    }

    function test_emits_Created_event() public {
        // get deployment address
        vm.prank(creator);
        address expectedAddress =
            ERC20FactoryFacet(address(app)).calculateERC20FactoryDeploymentAddress(erc20ImplementationId);

        vm.expectEmit(false, true, true, true);
        emit Created(expectedAddress, creator, "name", "symbol", 18, 1000, erc20ImplementationId);

        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
    }

    function test_reverts_when_do_not_have_permission() public {
        vm.expectRevert(IERC20Factory.ERC20Factory_doNotHavePermission.selector);
        vm.prank(other);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
    }

    function test_reverts_when_no_implementation_is_found() public {
        vm.expectRevert(IERC20Factory.ERC20Factory_noImplementationFound.selector);
        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, bytes32("wrong implementation id"));
    }

    function test_reverts_when_erc20_implementation_is_incompatible() public {
        BadERC20 badErc20Implementation = new BadERC20();
        bytes32 badErc20ImplementationId = bytes32("bad");

        globals.setERC20Implementation(badErc20ImplementationId, address(badErc20Implementation));

        vm.expectRevert(IERC20Factory.ERC20Factory_failedToInitialize.selector);
        vm.prank(creator);
        ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, badErc20ImplementationId);
    }

    function _approveCreatorAccess(address _account)
        internal
        returns (address[] memory accounts, bool[] memory approvals)
    {
        accounts = new address[](1);
        accounts[0] = address(_account); // native token

        approvals = new bool[](1);
        approvals[0] = true;

        vm.prank(creator);
        SettingsFacet(address(app)).setCreatorAccess(accounts, approvals);
    }
}

contract ERC20FactoryFacet__integration_getERC20FactoryImplementation is Setup {
    function test_returns_implementation_address() public {
        address implementation = ERC20FactoryFacet(address(app)).getERC20FactoryImplementation(erc20ImplementationId);
        assertEq(implementation, address(erc20Implementation));
    }

    function test_returns_zero_address_if_no_implementation_found() public {
        address implementation = ERC20FactoryFacet(address(app)).getERC20FactoryImplementation("");
        assertEq(implementation, address(0));
    }
}

contract ERC20FactoryFacet__integration_calculateERC20DeploymentAddress is Setup {
    function test_returns_correct_deployment_address() public {
        vm.prank(creator);
        address deploymentAddress =
            ERC20FactoryFacet(address(app)).calculateERC20FactoryDeploymentAddress(erc20ImplementationId);

        vm.prank(creator);
        address actualDeploymentAddress =
            ERC20FactoryFacet(address(app)).createERC20("name", "symbol", 18, 1000, erc20ImplementationId);
        assertEq(deploymentAddress, actualDeploymentAddress);
    }

    function test_reverts_if_no_implementation_found() public {
        vm.expectRevert(IERC20Factory.ERC20Factory_noImplementationFound.selector);
        address implementation = ERC20FactoryFacet(address(app)).calculateERC20FactoryDeploymentAddress("");
    }
}

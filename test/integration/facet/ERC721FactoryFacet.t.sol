// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that the platform fee extension works as intended within the ecosystem

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

import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {IERC721Factory} from "@extensions/ERC721Factory/IERC721Factory.sol";
import {ERC721Base, ADMIN_ROLE, MINTER_ROLE} from "src/tokens/ERC721/ERC721Base.sol";
import {ERC721LazyMint} from "src/tokens/ERC721/ERC721LazyMint.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";

import {SettingsFacet, IApplicationAccess} from "src/facet/SettingsFacet.sol";

// bad erc721 implementation without an initialize function
contract BadERC721 {}

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
    ERC721Base erc721Implementation;
    bytes32 erc721ImplementationId;
    ERC721FactoryFacet erc721FactoryFacet;

    function setUp() public {
        // assign addresses
        creator = address(0x10);
        other = address(0x11);
        socialConscious = address(0x12);

        vm.deal(creator, 1 ether);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new Proxy(true);
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        erc20Implementation = new ERC20Base();

        erc721Implementation = new ERC721Base();
        erc721ImplementationId = bytes32("Base");
        erc721FactoryFacet = new ERC721FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("ERC721LazyMintTest", creator)));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC721Implementation(erc721ImplementationId, address(erc721Implementation));

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
            // add erc721FactoryFacet to registry
            bytes4[] memory selectors = new bytes4[](3);
            selectors[0] = erc721FactoryFacet.createERC721.selector;
            selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
            selectors[2] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;
            registry.diamondCut(
                prepareSingleFacetCut(
                    address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
                ),
                address(0),
                ""
            );
        }

        _afterSetup();
    }

    function _afterSetup() internal virtual {}
}

contract ERC721FactoryFacet__integration_createERC721 is Setup {
    event Created(
        address id,
        address creator,
        string name,
        string symbol,
        address royaltyRecipient,
        uint16 royaltyBps,
        bytes32 implementationId
    );

    // to check contracts deployed to same address
    mapping(address => bool) deployments;

    function test_can_create_erc721() public {
        vm.prank(creator);
        address erc721Address =
            ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, erc721ImplementationId);

        assertEq(ERC721Base(erc721Address).name(), "name");
        assertEq(ERC721Base(erc721Address).symbol(), "symbol");
        (address receiver, uint256 royaltyAmount) = ERC721Base(erc721Address).royaltyInfo(0, 1 ether);
        assertEq(receiver, creator);
        assertEq(royaltyAmount, 0.1 ether);
        assertTrue(ERC721Base(erc721Address).hasRole(ADMIN_ROLE, creator));
        assertTrue(ERC721Base(erc721Address).hasRole(MINTER_ROLE, address(app)));
    }

    function test_can_create_erc721_and_pay_platform_fee() public {
        // set platform base fee to 1 ether
        globals.setPlatformFee(1 ether, 0, socialConscious);

        // create nft and pay platform fee
        vm.prank(creator);
        address erc721Address = ERC721FactoryFacet(address(app)).createERC721{value: 1 ether}(
            "name", "symbol", "", creator, 1000, erc721ImplementationId
        );
        // check platform fee has been received
        assertEq(socialConscious.balance, 1 ether);
    }

    function test_can_create_erc721_when_approved_creator() public {
        _approveCreatorAccess(other);

        vm.prank(other);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, erc721ImplementationId);
    }

    function test_can_create_multiple_erc721_contracts() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(creator);
            address deployed = ERC721FactoryFacet(address(app)).createERC721(
                "name", "symbol", "", creator, 1000, erc721ImplementationId
            );
            if (deployments[deployed] == true) {
                revert("ERC721 deployed to the same address");
            }

            deployments[deployed] = true;
        }
    }

    function test_can_create_erc721_when_zero_address_approved_creator() public {
        _approveCreatorAccess(address(0));

        vm.prank(other);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, erc721ImplementationId);
    }

    function test_grants_minter_role_with_lazy_mint_implementation() public {
        // add lazy mint implementation
        ERC721LazyMint lazyMintImplementation = new ERC721LazyMint(false);
        bytes32 lazyMintImplementationId = bytes32("LazyMint");
        globals.setERC721Implementation(lazyMintImplementationId, address(lazyMintImplementation));

        // create lazy mint erc721
        vm.prank(creator);
        address lazyMint =
            ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, lazyMintImplementationId);

        assertTrue(ERC721LazyMint(lazyMint).hasRole(MINTER_ROLE, address(app)));
    }

    function test_emits_Created_event() public {
        vm.prank(creator);
        address expectedAddress =
            ERC721FactoryFacet(address(app)).calculateERC721FactoryDeploymentAddress(erc721ImplementationId);

        vm.expectEmit(false, true, true, true);
        emit Created(expectedAddress, creator, "name", "symbol", creator, 1000, erc721ImplementationId);

        // create nft and pay platform fee
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, erc721ImplementationId);
    }

    function test_reverts_when_do_not_have_permission() public {
        vm.expectRevert(IERC721Factory.ERC721Factory_doNotHavePermission.selector);
        vm.prank(other);
        ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, erc721ImplementationId);
    }

    function test_reverts_when_no_implementation_is_found() public {
        vm.expectRevert(IERC721Factory.ERC721Factory_noImplementationFound.selector);
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721(
            "name", "symbol", "", creator, 1000, bytes32("wrong implementation id")
        );
    }

    function test_reverts_when_erc721_implementation_is_incompatible() public {
        BadERC721 badErc721Implementation = new BadERC721();
        bytes32 badErc721ImplementationId = bytes32("bad");

        globals.setERC721Implementation(badErc721ImplementationId, address(badErc721Implementation));

        vm.expectRevert(IERC721Factory.ERC721Factory_failedToInitialize.selector);
        vm.prank(creator);
        ERC721FactoryFacet(address(app)).createERC721{value: 1 ether}(
            "name", "symbol", "", creator, 1000, badErc721ImplementationId
        );
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

contract ERC721FactoryFacet__integration_getERC721FactoryImplementation is Setup {
    function test_returns_implementation_address() public {
        address implementation = ERC721FactoryFacet(address(app)).getERC721FactoryImplementation(erc721ImplementationId);
        assertEq(implementation, address(erc721Implementation));
    }

    function test_returns_zero_address_if_no_implementation_found() public {
        address implementation = ERC721FactoryFacet(address(app)).getERC721FactoryImplementation("");
        assertEq(implementation, address(0));
    }
}

contract ERC721FactoryFacet__integration_calculateERC721DeploymentAddress is Setup {
    function test_returns_correct_deployment_address() public {
        vm.prank(creator);
        address deploymentAddress =
            ERC721FactoryFacet(address(app)).calculateERC721FactoryDeploymentAddress(erc721ImplementationId);

        vm.prank(creator);
        address actualDeploymentAddress =
            ERC721FactoryFacet(address(app)).createERC721("name", "symbol", "", creator, 1000, erc721ImplementationId);
        assertEq(deploymentAddress, actualDeploymentAddress);
    }

    function test_reverts_if_no_implementation_found() public {
        vm.expectRevert(IERC721Factory.ERC721Factory_noImplementationFound.selector);
        address implementation = ERC721FactoryFacet(address(app)).calculateERC721FactoryDeploymentAddress("");
    }
}

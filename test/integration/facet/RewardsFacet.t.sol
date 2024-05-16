// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests ERC20Base integration with Globals ERC20FactoryFacet and platform fees

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

import {Proxy} from "src/proxy/Proxy.sol";
import {Upgradable} from "src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {AppFactory} from "src/factories/App.sol";
import {Globals} from "src/globals/Globals.sol";

import {ERC721Badge} from "src/tokens/ERC721/ERC721Badge.sol";
import {IERC721Factory} from "@extensions/ERC721Factory/IERC721Factory.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {IERC20Factory} from "@extensions/ERC20Factory/IERC20Factory.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";
import {RewardsFacet} from "src/facet/RewardsFacet.sol";
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
        ERC20Base(_erc20).mintTo(_account, _amount);
    }
}

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

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
    RewardsFacet rewardsFacet;

    ERC721Badge erc721Implementation;
    bytes32 erc721ImplementationId;
    ERC721FactoryFacet erc721FactoryFacet;

    ERC20Base erc20Implementation;
    bytes32 erc20ImplementationId;
    ERC20FactoryFacet erc20FactoryFacet;

    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";
    uint16 tenPercentBPS = 1000;

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

        erc721Implementation = new ERC721Badge(false);
        erc721ImplementationId = bytes32("Badge");
        erc721FactoryFacet = new ERC721FactoryFacet();

        erc20Implementation = new ERC20Base();
        erc20ImplementationId = bytes32("Base");
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("RewardFacetTest", creator)));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC721Implementation(erc721ImplementationId, address(erc721Implementation));
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

        rewardsFacet = new RewardsFacet();
        {
            // add RewardsFacet to registry
            bytes4[] memory selectors = new bytes4[](5);
            selectors[0] = rewardsFacet.mintERC20.selector;
            selectors[1] = rewardsFacet.transferERC20.selector;
            selectors[2] = rewardsFacet.mintERC721.selector;
            selectors[3] = rewardsFacet.transferERC721.selector;
            selectors[4] = rewardsFacet.multicall.selector;
            selectors[0] = rewardsFacet.mintBadge.selector;

            registry.diamondCut(
                prepareSingleFacetCut(address(rewardsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
                address(0),
                ""
            );
        }

        {
            // add erc721FactoryFacet to registry
            bytes4[] memory selectors = new bytes4[](4);
            selectors[0] = erc721FactoryFacet.createERC721.selector;
            selectors[1] = erc721FactoryFacet.createERC721WithTokenURI.selector;
            selectors[2] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
            selectors[3] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;
            registry.diamondCut(
                prepareSingleFacetCut(
                    address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
                ),
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

contract RewardFacet__integration_mintBadge is Setup {
    address badgeContractAddress;

    function _afterSetup() internal override {
        vm.startPrank(creator);
        badgeContractAddress = ERC721FactoryFacet(address(app)).createERC721WithTokenURI(
            "Name", "Symbol", "tokenURI", creator, uint16(tenPercentBPS), bytes32("Badge")
        );

        // TODO: can this be done on initialisation to reduce transactions needed
        ERC721Badge(badgeContractAddress).grantRole(MINTER_ROLE, address(app));

        vm.stopPrank();
    }

    function test_rewards_badge() public {
        vm.prank(creator);
        RewardsFacet(address(app)).mintBadge(badgeContractAddress, creator, 1, "action id?", "mission?", "random data");

        assertEq(ERC721Badge(badgeContractAddress).balanceOf(creator), 1);
    }
}

contract ERC20Base_Setup is Setup {
    ERC20Base base;
    MinterDummy minter;

    function _afterSetup() internal override {
        // add lazy mint implementation
        ERC20Base baseImplementation = new ERC20Base();
        bytes32 baseImplementationId = bytes32("Base");
        globals.setERC20Implementation(baseImplementationId, address(baseImplementation));

        // create lazy mint erc20
        vm.prank(creator);
        // forgefmt: disable-start
        base = ERC20Base(
            ERC20FactoryFacet(address(app)).createERC20(
                "name",
                "symbol",
                18,
                0,
                baseImplementationId
            )
        );
        // forgefmt: disable-end

        // create contract that can mint
        minter = new MinterDummy();
        // grant minter role to minter contract
        vm.prank(creator);
        base.grantRole(MINTER_ROLE, address(minter));
    }
}

contract RewardsFacet__integration_mintERC20 is ERC20Base_Setup {
    function test_mints_erc20() public {
        vm.prank(creator);
        base.mintTo(creator, 1000);

        // check nft is minted to creator
        assertEq(base.balanceOf(creator), 1000);
    }
}

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

import {ERC721Base} from "src/tokens/ERC721/ERC721Base.sol";
import {ERC721Badge} from "src/tokens/ERC721/ERC721Badge.sol";
import {IERC721Factory} from "@extensions/ERC721Factory/IERC721Factory.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {ERC20Point} from "src/tokens/ERC20/ERC20Point.sol";
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

    ERC721Base erc721Implementation;
    bytes32 erc721ImplementationId;
    ERC721Badge badgeImplementation;
    bytes32 badgeImplementationId;
    ERC721FactoryFacet erc721FactoryFacet;

    ERC20Base erc20Implementation;
    bytes32 erc20ImplementationId;
    ERC20Point erc20PointImplementation;
    bytes32 erc20PointImplementationId;

    ERC20FactoryFacet erc20FactoryFacet;

    string name = "Name";
    string symbol = "Symbol";
    bytes32 activityId = "collected a berry";
    bytes32 activityType = "action";
    // ipfs uri taken from https://docs.ipfs.tech/how-to/best-practices-for-nft-data/#types-of-ipfs-links-and-when-to-use-them
    string baseURI = "ipfs://bafybeibnsoufr2renqzsh347nrx54wcubt5lgkeivez63xvivplfwhtpym/";
    uint16 tenPercentBPS = 1000;
    uint256 oneEther = 1 ether;

    event TokenMinted(address token, address to, uint256 amount, bytes32 id, bytes32 activityType, string uri);
    event TokenTransferred(address token, address to, uint256 amount, bytes32 id, bytes32 activityType, string uri);
    event ERC721Minted(address token, uint256 quantity, address to, bytes32 id, bytes32 activityType, string uri);
    event BadgeMinted(address token, uint256 quantity, address to, bytes32 activityId, bytes32 activityType, bytes data);
    event BadgeTransferred(address token, address to, uint256 tokenId, bytes32 id, bytes32 activityType, string uri);

    function setUp() public {
        // assign addresses
        creator = address(0x10);
        other = address(0x11);
        socialConscious = address(0x12);

        vm.deal(creator, oneEther);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appImplementation = new Proxy(true);
        appFactory = new AppFactory(address(appImplementation), address(registry), address(globals));

        erc721Implementation = new ERC721Base();
        erc721ImplementationId = bytes32("Base");
        badgeImplementation = new ERC721Badge(false);
        badgeImplementationId = bytes32("Badge");
        erc721FactoryFacet = new ERC721FactoryFacet();

        erc20Implementation = new ERC20Base();
        erc20ImplementationId = bytes32("base");
        erc20PointImplementation = new ERC20Point();
        erc20PointImplementationId = bytes32("point");
        
        erc20FactoryFacet = new ERC20FactoryFacet();

        // create app
        vm.prank(creator);
        app = Proxy(payable(appFactory.create("RewardFacetTest", creator)));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC721Implementation(badgeImplementationId, address(badgeImplementation));
        globals.setERC721Implementation(erc721ImplementationId, address(erc721Implementation));
        globals.setERC20Implementation(erc20ImplementationId, address(erc20Implementation));
        globals.setERC20Implementation(erc20PointImplementationId, address(erc20PointImplementation));

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
            bytes4[] memory selectors = new bytes4[](7);
            selectors[0] = rewardsFacet.mintERC20.selector;
            selectors[1] = rewardsFacet.transferERC20.selector;
            selectors[2] = rewardsFacet.mintERC721.selector;
            selectors[3] = rewardsFacet.transferERC721.selector;
            selectors[4] = rewardsFacet.multicall.selector;
            selectors[5] = rewardsFacet.mintBadge.selector;
            selectors[6] = rewardsFacet.batchMintBadge.selector;

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
    address badgeContract;

    function _afterSetup() internal override {
        // use app to create badge contract
        vm.prank(creator);
        badgeContract = ERC721FactoryFacet(address(app)).createERC721WithTokenURI(
            name, symbol, baseURI, creator, uint16(tenPercentBPS), badgeImplementationId
        );
    }

    function test_rewards_badge() public {
        vm.prank(creator);
        RewardsFacet(address(app)).mintBadge(badgeContract, other, activityId, activityType, "");

        assertEq(ERC721Badge(badgeContract).balanceOf(other), 1);
    }

    function test_emits_badge_minted_event() public {
        vm.expectEmit(true, true, true, true);
        emit BadgeMinted(badgeContract, 1, other, activityId, activityType, "");

        vm.prank(creator);
        RewardsFacet(address(app)).mintBadge(badgeContract, other, activityId, activityType, "");
    }

    function test_can_encode_string_in_data_emitted_in_badge_minted_event() public {
        vm.expectEmit(true, true, true, true);
        emit BadgeMinted(badgeContract, 1, other, activityId, activityType, abi.encode("testing 123"));

        vm.prank(creator);
        RewardsFacet(address(app)).mintBadge(badgeContract, other, activityId, activityType, abi.encode("testing 123"));
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        vm.prank(creator);
        ERC721Badge(badgeContract).grantRole(MINTER_ROLE, other);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).mintBadge(badgeContract, other, activityId, activityType, "");
    }
}

contract RewardFacet__integration_batchMintBadge is Setup {
    address badgeContract;

    function _afterSetup() internal override {
        // use app to create badge contract
        vm.prank(creator);
        badgeContract = ERC721FactoryFacet(address(app)).createERC721WithTokenURI(
            name, symbol, baseURI, creator, uint16(tenPercentBPS), badgeImplementationId
        );
    }

    function test_rewards_multiple_badges() public {
        vm.prank(creator);
        RewardsFacet(address(app)).batchMintBadge(badgeContract, other, 10, activityId, activityType, "");

        assertEq(ERC721Badge(badgeContract).balanceOf(other), 10);
    }

    function test_emits_badge_minted_event() public {
        vm.expectEmit(true, true, true, true);
        emit BadgeMinted(badgeContract, 10, other, activityId, activityType, "");

        vm.prank(creator);
        RewardsFacet(address(app)).batchMintBadge(badgeContract, other, 10, activityId, activityType, "");
    }

    function test_can_encode_string_in_data_emitted_in_badge_minted_event() public {
        vm.expectEmit(true, true, true, true);
        emit BadgeMinted(badgeContract, 10, other, activityId, activityType, abi.encode("testing 123"));

        vm.prank(creator);
        RewardsFacet(address(app)).batchMintBadge(
            badgeContract, other, 10, activityId, activityType, abi.encode("testing 123")
        );
    }

    function test_reverts_when_app_is_not_granted_minter_role() public {
        vm.startPrank(creator);
        ERC721Badge(badgeContract).revokeRole(MINTER_ROLE, address(app));

        vm.expectRevert(ERC721Badge.ERC721Badge_notAuthorized.selector);
        RewardsFacet(address(app)).batchMintBadge(badgeContract, other, 10, activityId, activityType, "");
        vm.stopPrank();
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        vm.prank(creator);
        ERC721Badge(badgeContract).grantRole(MINTER_ROLE, other);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).batchMintBadge(badgeContract, other, 10, activityId, activityType, "");
    }
}

contract RewardFacet__integration_mintERC721 is Setup {
    address baseContract;

    function _afterSetup() internal override {
        // use app to create badge contract
        vm.prank(creator);
        baseContract = ERC721FactoryFacet(address(app)).createERC721(
            name, symbol, creator, uint16(tenPercentBPS), erc721ImplementationId
        );
    }

    function test_rewards_multiple_badges() public {
        vm.prank(creator);
        RewardsFacet(address(app)).mintERC721(baseContract, other, 10, baseURI, activityId, activityType, "");

        assertEq(ERC721Base(baseContract).balanceOf(other), 10);
    }

    function test_emits_erc721_minted_event() public {
        vm.expectEmit(true, true, true, true);
        emit ERC721Minted(baseContract, 10, other, activityId, activityType, "");

        vm.prank(creator);
        RewardsFacet(address(app)).mintERC721(baseContract, other, 10, baseURI, activityId, activityType, "");
    }

    function test_reverts_when_app_not_granted_minter_role() public {
        vm.startPrank(creator);
        ERC721Base(baseContract).revokeRole(MINTER_ROLE, address(app));

        vm.expectRevert(ERC721Base.ERC721Base_notAuthorized.selector);
        RewardsFacet(address(app)).mintERC721(baseContract, other, 10, baseURI, activityId, activityType, "");
        vm.stopPrank();
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        vm.prank(creator);
        ERC721Base(baseContract).grantRole(MINTER_ROLE, other);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).mintERC721(baseContract, other, 10, baseURI, activityId, activityType, "");
    }
}

contract RewardFacet__integration_transferERC721 is Setup {
    address baseContract;

    function _afterSetup() internal override {
        // use app to create badge contract
        vm.startPrank(creator);
        baseContract = ERC721FactoryFacet(address(app)).createERC721(
            name, symbol, creator, uint16(tenPercentBPS), erc721ImplementationId
        );

        // mint nft to creator and approve app as operator
        ERC721Base(baseContract).mintTo(creator, baseURI);
        ERC721Base(baseContract).setApprovalForAll(address(app), true);
        vm.stopPrank();
    }

    function test_setup() public {
        assertEq(ERC721Base(baseContract).ownerOf(0), creator);
        assertEq(ERC721Base(baseContract).isApprovedOrOwner(address(app), 0), true);
    }

    function test_transfers_erc721() public {
        vm.prank(creator);
        RewardsFacet(address(app)).transferERC721(baseContract, other, 0, activityId, activityType, "");

        assertEq(ERC721Base(baseContract).ownerOf(0), other);
        assertEq(ERC721Base(baseContract).isApprovedOrOwner(address(app), 0), false);
    }

    function test_emits_badge_transferred_event() public {
        vm.expectEmit(true, true, true, true);
        emit BadgeTransferred(baseContract, other, 0, activityId, activityType, "");

        vm.prank(creator);
        RewardsFacet(address(app)).transferERC721(baseContract, other, 0, activityId, activityType, "");
    }

    function test_reverts_when_app_not_approved() public {
        ERC721Base(baseContract).setApprovalForAll(address(app), false);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);

        vm.prank(other);
        RewardsFacet(address(app)).transferERC721(baseContract, other, 0, activityId, activityType, "");
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        // mint token 2 to other and approve app
        vm.prank(creator);
        ERC721Base(baseContract).mintTo(other, baseURI);
        vm.prank(other);
        ERC721Base(baseContract).setApprovalForAll(address(app), true);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).transferERC721(baseContract, other, 1, activityId, activityType, "");
    }
}

contract RewardFacet__integration_multicall is Setup {
    address badgeContract;

    function _afterSetup() internal override {
        // use app to create badge contract
        vm.prank(creator);
        badgeContract = ERC721FactoryFacet(address(app)).createERC721WithTokenURI(
            name, symbol, baseURI, creator, uint16(tenPercentBPS), badgeImplementationId
        );
    }

    function test_can_multicall_minting_badges() public {
        bytes[] memory calls = new bytes[](2);
        calls[0] =
            abi.encodeCall(RewardsFacet(address(app)).mintBadge, (badgeContract, other, activityId, activityType, ""));
        calls[1] = abi.encodeCall(
            RewardsFacet(address(app)).batchMintBadge, (badgeContract, creator, 10, activityId, activityType, "")
        );

        vm.prank(creator);
        RewardsFacet(address(app)).multicall(calls);

        assertEq(ERC721Badge(badgeContract).balanceOf(other), 1);
        assertEq(ERC721Badge(badgeContract).balanceOf(creator), 10);
    }
}

contract RewardsFacet__integration_mintERC20Base is Setup {
    address tokenContract;

    function _afterSetup() internal override {
        // use app to create credit contract
        vm.prank(creator);
        tokenContract = ERC20FactoryFacet(address(app)).createERC20(
            name, symbol, 18, oneEther, erc20ImplementationId
        );
    }

    function test_setup() public {
        assertEq(ERC20Base(tokenContract).balanceOf(creator), oneEther);
    }

    function test_mints_erc20() public {
        vm.prank(creator);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );

        assertEq(ERC20Base(tokenContract).balanceOf(other), oneEther);
    }

    function test_emits_token_minted_event() public {
        vm.expectEmit(true, true, true, true, address(app));
        emit TokenMinted(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );

        vm.prank(creator);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        // other has minter role
        vm.prank(creator);
        ERC20Base(tokenContract).grantRole(MINTER_ROLE, other);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }

    function test_reverts_when_caller_does_not_have_correct_roles_on_token_contract() public {
        // revoke admin and minter roles
        vm.prank(creator);
        ERC20Base(tokenContract).revokeRole(MINTER_ROLE, creator);
        vm.prank(creator);
        ERC20Base(tokenContract).revokeRole(ADMIN_ROLE, creator);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }
}

contract RewardsFacet__integration_mintERC20Point is Setup {
    address tokenContract;

    function _afterSetup() internal override {
        // use app to create credit contract
        vm.prank(creator);
        tokenContract = ERC20FactoryFacet(address(app)).createERC20(
            name, symbol, 18, oneEther, erc20PointImplementationId
        );
    }

    function test_setup() public {
        assertEq(ERC20Point(tokenContract).balanceOf(creator), oneEther);
    }

    function test_mints_erc20point() public {
        vm.prank(creator);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );

        assertEq(ERC20Point(tokenContract).balanceOf(other), oneEther);
    }

    function test_emits_token_minted_event() public {
        vm.expectEmit(true, true, true, true, address(app));
        emit TokenMinted(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );

        vm.prank(creator);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        // other has minter role
        vm.prank(creator);
        ERC20Point(tokenContract).grantRole(MINTER_ROLE, other);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }

    function test_reverts_when_caller_does_not_have_correct_roles_on_token_contract() public {
        // revoke admin and minter roles
        vm.prank(creator);
        ERC20Point(tokenContract).revokeRole(MINTER_ROLE, creator);
        vm.prank(creator);
        ERC20Point(tokenContract).revokeRole(ADMIN_ROLE, creator);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).mintERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }
}

contract RewardsFacet__integration_transferERC20Base is Setup {
    address tokenContract;

    function _afterSetup() internal override {
        // use app to create credit contract
        vm.prank(creator);
        tokenContract = ERC20FactoryFacet(address(app)).createERC20(
            name,
            symbol,
            18,
            oneEther,
            erc20ImplementationId
        );

        // approve spend allowance for app contract
        vm.prank(creator);
        ERC20Base(tokenContract).approve(address(app), oneEther);
    }

    function test_setup () public {
        assertEq(ERC20Base(tokenContract).balanceOf(creator), oneEther);
        assertEq(ERC20Base(tokenContract).allowance(creator, address(app)), oneEther);
    }

    function test_transfers_erc20() public {
        vm.prank(creator);
        RewardsFacet(address(app)).transferERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );

        assertEq(ERC20Base(tokenContract).balanceOf(other), oneEther);
    }

    function test_emits_token_transferred_event() public {
        vm.expectEmit(true, true, true, true, address(app));
        emit TokenTransferred(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );

        vm.prank(creator);
        RewardsFacet(address(app)).transferERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }

    function test_reverts_when_caller_is_not_the_app_operator() public {
        // other has a balance and has approved spend on token contract
        vm.prank(creator);
        ERC20Base(tokenContract).mintTo(other, oneEther);
        vm.prank(other);
        ERC20Base(tokenContract).approve(address(app), oneEther);

        vm.prank(other);
        vm.expectRevert(RewardsFacet.RewardsFacet_NotAuthorized.selector);
        RewardsFacet(address(app)).transferERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }
}

contract RewardsFacet__integration_transferERC20Point is Setup {
    address tokenContract;

    function _afterSetup() internal override {
        // use app to create credit contract
        vm.prank(creator);
        tokenContract = ERC20FactoryFacet(address(app)).createERC20(
            name,
            symbol,
            18,
            oneEther,
            erc20PointImplementationId
        );
    }

    function test_setup () public {
        assertEq(ERC20Point(tokenContract).balanceOf(creator), oneEther);
    }

    function test_approve() public {
        vm.prank(creator);
        vm.expectRevert(ERC20Point.ERC20Point_nonTransferableToken.selector);
        ERC20Point(tokenContract).approve(address(app), oneEther);
    }

    function test_transfer() public {
        vm.prank(creator);
        vm.expectRevert(ERC20Point.ERC20Point_nonTransferableToken.selector);
        RewardsFacet(address(app)).transferERC20(
            tokenContract,
            other,
            oneEther,
            activityId,
            activityType,
            ""
        );
    }
}
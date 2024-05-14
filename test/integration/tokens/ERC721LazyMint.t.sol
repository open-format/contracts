// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests ERC721LazyMint integration with Globals ERC721FactoryFacet and platform fees

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
import {ERC721Base, ADMIN_ROLE, MINTER_ROLE} from "src/tokens/ERC721/ERC721Base.sol";
import {ERC721LazyMint} from "src/tokens/ERC721/ERC721LazyMint.sol";
import {IERC721Factory} from "@extensions/ERC721Factory/IERC721Factory.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {SettingsFacet, IApplicationAccess} from "src/facet/SettingsFacet.sol";

import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

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
 *      must first grant ADMIN_ROLE to this contract
 */
contract ContractDummy {
    function mintTo(address _erc721, address _to) public {
        ERC721LazyMint(_erc721).mintTo(_to);
    }

    function batchMintTo(address _erc721, address _to, uint256 _quantity) public {
        ERC721LazyMint(_erc721).batchMintTo(_to, _quantity);
    }

    function lazyMint(address _erc721, uint256 _amount, string memory _baseURI) public {
        ERC721LazyMint(_erc721).lazyMint(_amount, _baseURI, "");
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

    /**
     * @dev override to add more setup per test contract
     */
    function _afterSetup() internal virtual {}
}

contract ERC721LazyMint_Setup is Setup {
    ERC721LazyMint lazyMint;
    ContractDummy contractDummy;

    function _afterSetup() internal override {
        // add lazy mint implementation
        ERC721LazyMint lazyMintImplementation = new ERC721LazyMint(false);
        bytes32 lazyMintImplementationId = bytes32("LazyMint");
        globals.setERC721Implementation(lazyMintImplementationId, address(lazyMintImplementation));

        // create lazy mint erc721
        vm.prank(creator);
        // forgefmt: disable-start
        lazyMint = ERC721LazyMint(
            ERC721FactoryFacet(address(app)).createERC721(
                "name",
                "symbol",
                creator,
                1000,
                lazyMintImplementationId
            )
        );
        // forgefmt: disable-end

        vm.prank(creator);
        lazyMint.lazyMint(3, "ipfs://", "");

        // create contract that can mint
        contractDummy = new ContractDummy();
        // grant admin role to minter contract
        vm.prank(creator);
        lazyMint.grantRole(ADMIN_ROLE, address(contractDummy));
    }
}

contract ERC721LazyMint__integration_mintTo is ERC721LazyMint_Setup {
    function test_mints_nft() public {
        vm.prank(creator);
        lazyMint.mintTo(creator);

        // check nft is minted to creator
        assertEq(lazyMint.ownerOf(0), creator);
    }

    function test_pays_platform_fee() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.prank(creator);
        lazyMint.mintTo{value: basePlatformFee}(creator);

        // check platform fee has been received
        assertEq(socialConscious.balance, basePlatformFee);
    }

    function test_reverts_if_platform_fee_not_supplied() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.expectRevert(CurrencyTransferLib.CurrencyTransferLib_insufficientValue.selector);
        vm.prank(creator);
        lazyMint.mintTo(creator);
    }

    function test_does_not_pay_platform_fee_when_called_from_contract() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        contractDummy.mintTo(address(lazyMint), creator);
        assertEq(lazyMint.ownerOf(0), creator);
    }
}

contract ERC721LazyMint__integration_batchMintTo is ERC721LazyMint_Setup {
    function test_batch_mints_nfts() public {
        vm.prank(creator);
        lazyMint.batchMintTo(creator, 3);

        // check nft is minted to creator
        assertEq(lazyMint.ownerOf(0), creator);
        assertEq(lazyMint.ownerOf(1), creator);
        assertEq(lazyMint.ownerOf(2), creator);
    }

    function test_pays_platform_fee() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        uint256 quantity = 3;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.prank(creator);
        lazyMint.batchMintTo{value: basePlatformFee * quantity}(creator, quantity);

        // check platform fee has been received
        assertEq(socialConscious.balance, basePlatformFee * quantity);
    }

    function test_reverts_if_platform_fee_not_supplied() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.expectRevert(CurrencyTransferLib.CurrencyTransferLib_insufficientValue.selector);
        vm.prank(creator);
        lazyMint.batchMintTo(creator, 3);
    }

    function test_does_not_pay_platform_fee_when_called_from_contract() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        contractDummy.batchMintTo(address(lazyMint), creator, 3);
        assertEq(lazyMint.ownerOf(0), creator);
        assertEq(lazyMint.ownerOf(1), creator);
        assertEq(lazyMint.ownerOf(2), creator);
    }
}

contract ERC721LazyMint__integration_lazyMint is ERC721LazyMint_Setup {
    function test_pays_platform_fee() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.prank(creator);
        lazyMint.lazyMint{value: basePlatformFee}(3, "ipfs://", "");

        // check platform fee has been received
        assertEq(socialConscious.balance, basePlatformFee);
    }

    function test_reverts_if_platform_fee_not_supplied() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        vm.expectRevert(CurrencyTransferLib.CurrencyTransferLib_insufficientValue.selector);
        vm.prank(creator);
        lazyMint.lazyMint(3, "ipfs://", "");
        assertEq(lazyMint.tokenURI(2), "ipfs://");
    }

    function test_does_not_pay_platform_fee_when_called_from_contract() public {
        // set platform base fee to 0.001 ether
        uint256 basePlatformFee = 0.001 ether;
        globals.setPlatformFee(basePlatformFee, 0, socialConscious);

        contractDummy.lazyMint(address(lazyMint), 3, "ipfs://");
        assertEq(lazyMint.tokenURI(2), "ipfs://");
    }
}

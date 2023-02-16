// SPDX-License-Identifier: UNLICENSED
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
import {Factory} from "src/factory/Factory.sol";
import {Globals} from "src/globals/Globals.sol";

import {ERC721Base} from "src/tokens/ERC721/ERC721Base.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";

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

    Factory appFactory;
    Proxy appImplementation;
    Proxy app;
    RegistryMock registry;
    Globals globals;

    ERC721Base erc721Implementation;
    ERC721FactoryFacet erc721FactoryFacet;

    function setUp() public {
        // assign addresses
        creator = address(0x10);
        socialConscious = address(0x11);

        // deploy contracts
        globals = new Globals();
        registry = new RegistryMock();
        appTemplate = new  Proxy(true);
        appFactory = new Factory(address(template), address(registry), address(globals));

        erc721Implementation = new ERC721Base();
        erc721FactoryFacet = new ERC721FactoryFacet();

        // create app
        app = Proxy(payable(appFactory.create("platformFeeTest")));

        // setup globals
        globals.setPlatformFee(0, 0, socialConscious);
        globals.setERC721Implementation(erc721Implementation);

        // add facet to registry
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(facet), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );
    }
}

contract ERC721FactoryFacet__intergration {}

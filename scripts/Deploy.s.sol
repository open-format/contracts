// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {RegistryMock} from "src/registry/RegistryMock.sol";
import {Proxy} from "src/proxy/ProxyMock.sol";
import {Factory} from "src/factory/Factory.sol";
import {Globals} from "src/globals/Globals.sol";
import {ERC721Base} from "src/tokens/ERC721/ERC721Base.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";

import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";
import {SettingsFacet} from "src/facet/SettingsFacet.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = new Globals();
        RegistryMock registry = new RegistryMock();
        Proxy template = new Proxy(true);
        Factory factory = new Factory(address(template), address(registry), address(globals));

        // Templates
        ERC721Base erc721template = new ERC721Base();
        ERC20Base erc20template = new ERC20Base();

        // Set globals
        globals.setERC721Implementation(address(erc721template));
        globals.setERC20Implementation(address(erc20template));

        // Facets
        SettingsFacet settingsFacet = new SettingsFacet();
        ERC721FactoryFacet erc721Factory = new ERC721FactoryFacet();
        ERC20FactoryFacet erc20Factory = new ERC20FactoryFacet();

        // Add facets to registry
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](3);
        // SettingsFacet
        {
            bytes4[] memory selectors = new bytes4[](3);
            selectors[0] = settingsFacet.setApplicationFee.selector;
            selectors[1] = settingsFacet.setAcceptedCurrencies.selector;
            selectors[2] = settingsFacet.applicationFeeInfo.selector;

            cuts[0] = IDiamondWritableInternal.FacetCut(
                address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
            );
        }
        // ERC721Factory
        {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = erc721Factory.createERC721.selector;
            selectors[1] = erc721Factory.getERC721FactoryImplementation.selector;

            cuts[1] = IDiamondWritableInternal.FacetCut(
                address(erc721Factory), IDiamondWritableInternal.FacetCutAction.ADD, selectors
            );
        }
        // ERC20Factory
        {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = erc20Factory.createERC20.selector;
            selectors[1] = erc20Factory.getERC20FactoryImplementation.selector;

            cuts[2] = IDiamondWritableInternal.FacetCut(
                address(erc20Factory), IDiamondWritableInternal.FacetCutAction.ADD, selectors
            );
        }

        registry.diamondCut(cuts, address(0), "");

        // create an app
        address appAddress = factory.create("app-name");
        Proxy app = Proxy(payable(appAddress));

        // deploy nft
        // ERC721Factory(appAddress).createERC721("hello", "hello", address(0x10), 1000);

        console.log("THIS IS YOUR APP >>>>>> %s", appAddress);

        vm.stopBroadcast();
    }
}

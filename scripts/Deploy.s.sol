// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {RegistryMock} from "../src/registry/RegistryMock.sol";
import {Proxy} from "../src/proxy/ProxyMock.sol";
import {Factory} from "../src/factory/Factory.sol";
import {Globals} from "../src/globals/Globals.sol";
import {ERC721Base} from "../src/tokens/ERC721/ERC721Base.sol";

import {ERC721Factory} from "../src/factory/ERC721Factory/ERC721Factory.sol";

contract DeployRegistry is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = new Globals();
        RegistryMock registry = new RegistryMock();
        Proxy template = new Proxy(true);
        Factory factory = new Factory(address(template), address(registry), address(globals));

        ERC721Base erc721template = new ERC721Base();
        // save across all of open format
        globals.setERC721Implementation(address(erc721template));

        // FACETS
        ERC721Factory erc721Factory = new ERC721Factory();

        // Add facets to registy
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        // ERC721Factory
        {
            bytes4[] memory selectors = new bytes4[](2);
            selectors[0] = ERC721Factory.createERC721.selector;
            selectors[1] = ERC721Factory.getERC721FactoryImplementation.selector;
            cuts[0] = IDiamondWritableInternal.FacetCut(
                address(erc721Factory), IDiamondWritableInternal.FacetCutAction.ADD, selectors
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

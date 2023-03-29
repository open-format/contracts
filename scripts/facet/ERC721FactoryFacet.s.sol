// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "ERC721FactoryFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721FactoryFacet erc721FactoryFacet = new ERC721FactoryFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        selectors[2] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721FactoryFacet), block.number);
    }
}

contract Update is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy new facet
        ERC721FactoryFacet erc721FactoryFacet = new ERC721FactoryFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        selectors[2] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

        // construct and REPLACE facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, selectors
        );

        // replace on registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        // update new address
        exportContractDeployment(CONTRACT_NAME, address(erc721FactoryFacet), block.number);
    }
}

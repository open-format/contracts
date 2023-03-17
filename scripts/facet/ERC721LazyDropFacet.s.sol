// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721LazyDropFacet} from "src/facet/ERC721LazyDropFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "ERC721LazyDropFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721LazyDropFacet erc721LazyDropFacet = new ERC721LazyDropFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = erc721LazyDropFacet.ERC721LazyDrop_getClaimCondition.selector;
        selectors[1] = erc721LazyDropFacet.ERC721LazyDrop_verifyClaim.selector;
        selectors[2] = erc721LazyDropFacet.ERC721LazyDrop_claim.selector;
        selectors[3] = erc721LazyDropFacet.ERC721LazyDrop_setClaimCondition.selector;
        selectors[4] = erc721LazyDropFacet.ERC721LazyDrop_removeClaimCondition.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc721LazyDropFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721LazyDropFacet), block.number);
    }
}

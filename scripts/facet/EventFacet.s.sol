// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {EventFacet} from "src/facet/EventFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";

string constant CONTRACT_NAME = "EventFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        EventFacet eventFacet = new EventFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = eventFacet.mintERC20.selector;
        selectors[1] = eventFacet.transferERC20.selector;
        selectors[2] = eventFacet.mintERC721.selector;
        selectors[3] = eventFacet.transferERC721.selector;
        selectors[4] = eventFacet.multicall.selector;
        selectors[5] = eventFacet.addMetadata.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(eventFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(eventFacet), block.number);
    }
}

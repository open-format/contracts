// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {RewardsFacet} from "src/facet/RewardsFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";

string constant CONTRACT_NAME = "RewardFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        RewardsFacet rewardsFacet = new RewardsFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = rewardsFacet.mintERC20.selector;
        selectors[1] = rewardsFacet.transferERC20.selector;
        selectors[2] = rewardsFacet.mintERC721.selector;
        selectors[3] = rewardsFacet.transferERC721.selector;
        selectors[4] = rewardsFacet.multicall.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(rewardsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(rewardsFacet), block.number);
    }
}

contract Update is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        RewardsFacet rewardsFacet = new RewardsFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = rewardsFacet.mintERC20.selector;
        selectors[1] = rewardsFacet.transferERC20.selector;
        selectors[2] = rewardsFacet.mintERC721.selector;
        selectors[3] = rewardsFacet.transferERC721.selector;
        selectors[4] = rewardsFacet.multicall.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(rewardsFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(rewardsFacet), block.number);
    }
}

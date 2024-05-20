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
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = rewardsFacet.mintERC20.selector;
        selectors[1] = rewardsFacet.transferERC20.selector;
        selectors[2] = rewardsFacet.mintERC721.selector;
        selectors[3] = rewardsFacet.transferERC721.selector;
        selectors[4] = rewardsFacet.multicall.selector;
        selectors[5] = rewardsFacet.mintBadge.selector;
        selectors[6] = rewardsFacet.batchMintBadge.selector;

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
        bytes4[] memory selectors = new bytes4[](7);
        selectors[0] = rewardsFacet.mintERC20.selector;
        selectors[1] = rewardsFacet.transferERC20.selector;
        selectors[2] = rewardsFacet.mintERC721.selector;
        selectors[3] = rewardsFacet.transferERC721.selector;
        selectors[4] = rewardsFacet.multicall.selector;
        selectors[5] = rewardsFacet.mintBadge.selector;
        selectors[6] = rewardsFacet.batchMintBadge.selector;

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

contract mintBadge is Script, Utils {
    function run(address _badgeContract) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        RewardsFacet rewardsFacet = RewardsFacet(appId);

        rewardsFacet.mintBadge(_badgeContract, deployerAddress, "collected berries", "action", "");

        vm.stopBroadcast();
    }
}

contract batchMintBadge is Script, Utils {
    function run(address _badgeContract) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        RewardsFacet rewardsFacet = RewardsFacet(appId);

        rewardsFacet.batchMintBadge(_badgeContract, deployerAddress, 10, "collected berries", "action", "");

        vm.stopBroadcast();
    }
}

/**
 * @dev use this script to updated deployments made previous to PR #126 https://github.com/open-format/contracts/pull/126/files
 */
contract Update_Add_badgeMintingFunctionality is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        RewardsFacet rewardsFacet = new RewardsFacet();

        // construct array of function selectors to replace
        bytes4[] memory replaceSelectors = new bytes4[](5);
        replaceSelectors[0] = rewardsFacet.mintERC20.selector;
        replaceSelectors[1] = rewardsFacet.transferERC20.selector;
        replaceSelectors[2] = rewardsFacet.mintERC721.selector;
        replaceSelectors[3] = rewardsFacet.transferERC721.selector;
        replaceSelectors[4] = rewardsFacet.multicall.selector;

        // construct array of function selectors to add
        bytes4[] memory addSelectors = new bytes4[](2);
        addSelectors[0] = rewardsFacet.mintBadge.selector;
        addSelectors[1] = rewardsFacet.batchMintBadge.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](2);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(rewardsFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(rewardsFacet), IDiamondWritableInternal.FacetCutAction.ADD, addSelectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(rewardsFacet), block.number);
    }
}

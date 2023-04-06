// SPDX-License-Identifier: Apache-2.0
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
address constant ERC20_ADDRESS = 0xc8a0c0aCc1ABbD8cE65Df85533e8CCe0cE37B478;
address constant HOLDER_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
address constant ERC721_ADDRESS = 0xC3Eb8951888faA683B928db44d90e1520dA891F6;
uint256 constant AMOUNT = 100000000000000000000000000;
string constant ID = "connect";
string constant ACTIVITY_TYPE = "mission";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        RewardsFacet rewardsFacet = new RewardsFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = rewardsFacet.mintERC20.selector;
        selectors[1] = rewardsFacet.transferERC20.selector;
        selectors[2] = rewardsFacet.mintERC721.selector;
        selectors[3] = rewardsFacet.multicall.selector;

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
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = rewardsFacet.mintERC20.selector;
        selectors[1] = rewardsFacet.transferERC20.selector;
        selectors[2] = rewardsFacet.mintERC721.selector;
        selectors[3] = rewardsFacet.multicall.selector;

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

contract MintERC20 is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        // Get reward facet
        RewardsFacet rewardsFacet = RewardsFacet(appId);

        rewardsFacet.mintERC20(ERC20_ADDRESS, address(0x2), AMOUNT, ID, appId, ACTIVITY_TYPE);

        vm.stopBroadcast();
    }
}

contract TransferERC20 is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        // Get reward facet
        RewardsFacet rewardsFacet = RewardsFacet(appId);

        ERC20Base erc20Base = ERC20Base(ERC20_ADDRESS);

        erc20Base.approve(appId, AMOUNT);

        // rewardsFacet.transferERC20(HOLDER_ADDRESS, ERC20_ADDRESS, address(0x5), AMOUNT, ID, appId, ACTIVITY_TYPE);

        vm.stopBroadcast();
    }
}

contract MintERC721 is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        // Get reward facet
        RewardsFacet rewardsFacet = RewardsFacet(appId);

        rewardsFacet.mintERC721(ERC721_ADDRESS, address(0x2), "ipfs://", ID, appId, ACTIVITY_TYPE);

        vm.stopBroadcast();
    }
}

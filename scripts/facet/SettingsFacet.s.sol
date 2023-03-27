// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {SettingsFacet} from "src/facet/SettingsFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "SettingsFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        SettingsFacet settingsFacet = new SettingsFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = settingsFacet.setApplicationFee.selector;
        selectors[1] = settingsFacet.setAcceptedCurrencies.selector;
        selectors[2] = settingsFacet.applicationFeeInfo.selector;
        selectors[3] = settingsFacet.setCreatorAccess.selector;
        selectors[4] = settingsFacet.hasCreatorAccess.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(settingsFacet), block.number);
    }
}

// creatorAccess - patch - 0x021d69f0e5032a924fdb0efa0b962dc6140038d4a82cee7de0b344deb1337086
contract Patch is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // deploy
        SettingsFacet settingsFacet = SettingsFacet(getContractDeploymentAddress(CONTRACT_NAME));

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = settingsFacet.setCreatorAccess.selector;
        selectors[1] = settingsFacet.hasCreatorAccess.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");
        vm.stopBroadcast();
    }
}

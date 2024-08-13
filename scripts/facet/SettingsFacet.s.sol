// SPDX-License-Identifier: BUSL-1.1
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
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = settingsFacet.setCreatorAccess.selector;
        selectors[1] = settingsFacet.hasCreatorAccess.selector;
        selectors[2] = settingsFacet.getGlobalsAddress.selector;

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

// expose globals - patch
contract Update_ExposeGlobals is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy new settings facet
        SettingsFacet settingsFacet = new SettingsFacet();

        // construct array of function selectors to replace
        // keeping it neat having all selectors point to the latest deployment
        bytes4[] memory replaceSelectors = new bytes4[](5);
        replaceSelectors[0] = bytes4(keccak256(bytes("setApplicationFee(uint16,address)")));
        replaceSelectors[1] = bytes4(keccak256(bytes("setAcceptedCurrencies(address[],bool[])")));
        replaceSelectors[2] = bytes4(keccak256(bytes("applicationFeeInfo(uint256)")));
        replaceSelectors[3] = settingsFacet.setCreatorAccess.selector;
        replaceSelectors[4] = settingsFacet.hasCreatorAccess.selector;

        // add globals
        bytes4[] memory addSelectors = new bytes4[](2);
        addSelectors[0] = bytes4(keccak256(bytes("platformFeeInfo(uint256)")));
        addSelectors[1] = settingsFacet.getGlobalsAddress.selector;

        // construct REPLACE and ADD facet cuts
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](2);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, addSelectors
        );

        // update registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");
        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(settingsFacet), block.number);
    }
}

/**
 * @dev updates settings facet to remove platform and application fee logic
 */
contract Update_Remove_Platform_and_Application_Fees is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        SettingsFacet settingsFacet = new SettingsFacet();

        // construct array of function selectors to remove
        bytes4[] memory removeSelectors = new bytes4[](4);
        removeSelectors[0] = bytes4(keccak256(bytes("platformFeeInfo(uint256)")));
        removeSelectors[1] = bytes4(keccak256(bytes("setApplicationFee(uint16,address)")));
        removeSelectors[2] = bytes4(keccak256(bytes("applicationFeeInfo(uint256)")));
        removeSelectors[3] = bytes4(keccak256(bytes("setAcceptedCurrencies(address[],bool[])")));

        // construct array of function selectors to replace
        bytes4[] memory replaceSelectors = new bytes4[](3);
        replaceSelectors[0] = settingsFacet.setCreatorAccess.selector;
        replaceSelectors[1] = settingsFacet.hasCreatorAccess.selector;
        replaceSelectors[2] = settingsFacet.getGlobalsAddress.selector;

        // construct and perform facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](2);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(0), IDiamondWritableInternal.FacetCutAction.REMOVE, removeSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(settingsFacet), block.number);
    }
}

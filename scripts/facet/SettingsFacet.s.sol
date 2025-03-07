// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {SettingsFacet, OPERATOR_ROLE} from "src/facet/SettingsFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "SettingsFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        SettingsFacet settingsFacet = new SettingsFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = settingsFacet.setApplicationFee.selector;
        selectors[1] = settingsFacet.setAcceptedCurrencies.selector;
        selectors[2] = settingsFacet.applicationFeeInfo.selector;
        selectors[3] = settingsFacet.setCreatorAccess.selector;
        selectors[4] = settingsFacet.hasCreatorAccess.selector;
        selectors[5] = settingsFacet.platformFeeInfo.selector;
        selectors[6] = settingsFacet.getGlobalsAddress.selector;
        selectors[7] = settingsFacet.enableAccessControl.selector;
        selectors[8] = settingsFacet.grantRole.selector;
        selectors[9] = settingsFacet.hasRole.selector;
        selectors[10] = settingsFacet.getRoleAdmin.selector;
        selectors[11] = settingsFacet.revokeRole.selector;
        selectors[12] = settingsFacet.renounceRole.selector;

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

contract EnableAccessControl is Script, Utils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        SettingsFacet(appId).enableAccessControl();
        vm.stopBroadcast();
    }
}

contract GrantRoleOperator is Script, Utils {
    function run(address account) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        SettingsFacet(appId).grantRole(OPERATOR_ROLE, account);
        vm.stopBroadcast();
    }
}

/**
 * @dev use this script to updated deployments of SettingsFacet from v1.0.0 to v1.1.0
 * PR #155 https://github.com/open-format/contracts/pull/155
 */
contract Update_AddAccessControl is Script, Utils {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // deploy
        SettingsFacet settingsFacet = new SettingsFacet();

        bytes4[] memory replaceSelectors = new bytes4[](7);
        replaceSelectors[0] = settingsFacet.setApplicationFee.selector;
        replaceSelectors[1] = settingsFacet.setAcceptedCurrencies.selector;
        replaceSelectors[2] = settingsFacet.applicationFeeInfo.selector;
        replaceSelectors[3] = settingsFacet.setCreatorAccess.selector;
        replaceSelectors[4] = settingsFacet.hasCreatorAccess.selector;
        replaceSelectors[5] = settingsFacet.platformFeeInfo.selector;
        replaceSelectors[6] = settingsFacet.getGlobalsAddress.selector;

        // construct array of function selectors to add
        bytes4[] memory addSelectors = new bytes4[](6);
        addSelectors[0] = settingsFacet.enableAccessControl.selector;
        addSelectors[1] = settingsFacet.grantRole.selector;
        addSelectors[2] = settingsFacet.hasRole.selector;
        addSelectors[3] = settingsFacet.getRoleAdmin.selector;
        addSelectors[4] = settingsFacet.revokeRole.selector;
        addSelectors[5] = settingsFacet.renounceRole.selector;

        // construct facet cuts
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](2);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(settingsFacet), IDiamondWritableInternal.FacetCutAction.ADD, addSelectors
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
        replaceSelectors[0] = settingsFacet.setApplicationFee.selector;
        replaceSelectors[1] = settingsFacet.setAcceptedCurrencies.selector;
        replaceSelectors[2] = settingsFacet.applicationFeeInfo.selector;
        replaceSelectors[3] = settingsFacet.setCreatorAccess.selector;
        replaceSelectors[4] = settingsFacet.hasCreatorAccess.selector;

        // add globals
        bytes4[] memory addSelectors = new bytes4[](2);
        addSelectors[0] = settingsFacet.platformFeeInfo.selector;
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

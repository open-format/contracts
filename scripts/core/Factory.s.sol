// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Factory} from "src/factory/Factory.sol";

string constant CONTRACT_NAME = "Factory";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address proxy = getContractDeploymentAddress("Proxy");
        address registry = getContractDeploymentAddress("Registry");
        address globals = getContractDeploymentAddress("Globals");

        if (proxy == address(0) || registry == address(0) || globals == address(0)) {
            revert("cannot find deployments, make sure to deploy Proxy, Registry, Globals first");
        }

        Factory factory = new Factory(proxy, registry, globals);

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(factory), block.number);
    }
}

contract CreateApp is Script, Utils {
    function run(string memory appName) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes32 appNameBytes32 = vm.parseBytes32(appName);

        if (appNameBytes32.length == 0) {
            revert("please provide an app name, make CreateApp args=appName");
        }

        address appAddress = Factory(getContractDeploymentAddress(CONTRACT_NAME)).create(appNameBytes32);

        console.log("App:", appName);
        console.log("Deployed:", appAddress);

        vm.stopBroadcast();
    }
}

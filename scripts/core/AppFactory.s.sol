// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {AppFactory} from "src/factories/App.sol";

string constant CONTRACT_NAME = "AppFactory";

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

        AppFactory factory = new AppFactory(proxy, registry, globals);

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(factory), block.number);
    }
}

contract CreateApp is Script, Utils {
    function run(string memory appName) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        bytes32 appNameBytes32 = vm.parseBytes32(appName);

        if (appNameBytes32.length == 0) {
            revert("please provide an app name, make CreateApp args=appName");
        }

        address appAddress =
            AppFactory(getContractDeploymentAddress(CONTRACT_NAME)).create(appNameBytes32, deployerAddress);

        console.log("App:", appName);
        console.log("Deployed:", appAddress);

        vm.stopBroadcast();
    }
}

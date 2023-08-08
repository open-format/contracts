// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ConstellationFactory} from "src/factories/Constellation.sol";

string constant CONTRACT_NAME = "ConstellationFactory";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        address erc20Base = getContractDeploymentAddress("ERC20Base");
        address globals = getContractDeploymentAddress("Globals");

        if (globals == address(0)) {
            revert("cannot find deployments, make sure to deploy ERC20Base and Globals first");
        }

        ConstellationFactory factory = new ConstellationFactory(erc20Base, globals);

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(factory), block.number);
    }
}

contract CreateConstellation is Script, Utils {
    function run(string memory appName) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        bytes32 appNameBytes32 = vm.parseBytes32(appName);

        if (appNameBytes32.length == 0) {
            revert("please provide an app name, make CreateApp args=appName");
        }

        address appAddress =
            ConstellationFactory(getContractDeploymentAddress(CONTRACT_NAME)).create("constellation_A", "CA", 18, 1000);

        console.log("App:", appName);
        console.log("Deployed:", appAddress);

        vm.stopBroadcast();
    }
}

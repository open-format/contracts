// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Factory} from "src/factory/Factory.sol";

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

        exportContractDeployment("Factory", address(factory), block.number);
    }
}

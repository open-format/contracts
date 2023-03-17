// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Proxy} from "src/proxy/Proxy.sol";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Proxy proxy = new Proxy(true);
        exportContractDeployment("Proxy", address(proxy), block.number);

        vm.stopBroadcast();
    }
}

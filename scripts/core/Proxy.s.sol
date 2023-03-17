// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Proxy} from "src/proxy/Proxy.sol";

string constant CONTRACT_NAME = "Proxy";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Proxy proxy = new Proxy(true);

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(proxy), block.number);
    }
}

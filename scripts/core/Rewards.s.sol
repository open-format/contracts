// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Rewards} from "src/rewards/Rewards.sol";

string constant CONTRACT_NAME = "Rewards";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Rewards rewards = new Rewards();

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(rewards), block.number);
    }
}

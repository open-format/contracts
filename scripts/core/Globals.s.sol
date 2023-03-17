// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Globals} from "src/globals/Globals.sol";
import "forge-std/console.sol";

// TODO: deploy behind a upgradeable proxy see solidstate-solidity/contracts/proxy/upgradeable/UpgradeableProxyOwnable.sol
string constant CONTRACT_NAME = "Globals";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = new Globals();

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(globals), block.number);
    }
}

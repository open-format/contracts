// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Billing} from "src/billing/Billing.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "Billing";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        address governorAddress = vm.envAddress("GOVERNOR_ADDRESS");
        address collectorAddress = vm.envAddress("COLLECTOR_ADDRESS");
        address oftTokenAddress = vm.envAddress("OFT_TOKEN_ADDRESS");
        bool canUpdateToken = false;

        vm.startBroadcast(deployerPrivateKey);

        // deploy
        Billing billing = new Billing(collectorAddress, oftTokenAddress, governorAddress, canUpdateToken);

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setBillingContract(address(billing));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(billing), block.number);

        console.log("Billing Contract Address:", address(billing));
    }
}

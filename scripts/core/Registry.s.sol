// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
// TODO: use Registry instead of RegistryMock
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "Registry";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        RegistryMock registry = new RegistryMock();

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(registry), block.number);
    }
}

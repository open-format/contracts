// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Globals} from "src/globals/Globals.sol";
import "forge-std/console.sol";

// TODO: deploy behind a upgradeable proxy see solidstate-solidity/contracts/proxy/upgradeable/UpgradeableProxyOwnable.sol

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = new Globals();
        exportContractDeployment("Globals", address(globals), block.number);

        vm.stopBroadcast();
    }
}

contract SetERC721Implementation is Script, Utils {
    function run(string memory implementationId, string memory contractName) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = Globals(getContractDeploymentAddress("Globals"));
        globals.setERC721Implementation(
            bytes32(abi.encode(implementationId)), getContractDeploymentAddress(contractName)
        );
        vm.stopBroadcast();
    }
}

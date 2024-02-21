// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ConstellationERC20Base} from "src/tokens/ERC20/ConstellationERC20Base.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ConstellationERC20Base";
bytes32 constant implementationId = "ConstellationBase";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ConstellationERC20Base constellationERC20Base = new ConstellationERC20Base();

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC20Implementation(implementationId, address(constellationERC20Base));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(constellationERC20Base), block.number);
    }
}

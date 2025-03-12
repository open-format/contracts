// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC20Point} from "src/tokens/ERC20/ERC20Point.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC20Point";
bytes32 constant implementationId = "Point";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC20Point erc20point = new ERC20Point();

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC20Implementation(implementationId, address(erc20point));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc20point), block.number);
    }
}

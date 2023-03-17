// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC20Base";
bytes32 constant implementationId = "Base";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC20Base erc20base = new ERC20Base();

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC20Implementation(implementationId, address(erc20base));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc20base), block.number);
    }
}

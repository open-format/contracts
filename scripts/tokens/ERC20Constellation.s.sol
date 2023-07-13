// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC20Constellation} from "src/tokens/ERC20/ERC20Constellation.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC20Constellation";
bytes32 constant implementationId = "Constellation";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC20Constellation erc20Constellation = new ERC20Constellation();

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC20Implementation(
            implementationId, address(erc20Constellation)
        );

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc20Constellation), block.number);
    }
}

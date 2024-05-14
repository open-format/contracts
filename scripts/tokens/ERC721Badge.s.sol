// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721Badge} from "src/tokens/ERC721/ERC721Badge.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC721Badge";
bytes32 constant implementationId = "Badge";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721Badge erc721Badge = new ERC721Badge(false);

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC721Implementation(implementationId, address(erc721Badge));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721Badge), block.number);
    }
}

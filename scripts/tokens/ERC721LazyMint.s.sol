// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721LazyMint} from "src/tokens/ERC721/ERC721LazyMint.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC721LazyMint";
bytes32 constant implementationId = "LazyMint";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721LazyMint erc721LazyMint = new ERC721LazyMint(false);

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC721Implementation(
            implementationId, address(erc721LazyMint)
        );

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721LazyMint), block.number);
    }
}

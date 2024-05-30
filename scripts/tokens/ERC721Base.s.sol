// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721Base} from "src/tokens/ERC721/ERC721Base.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC721Base";
bytes32 constant implementationId = "Base";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721Base erc721base = new ERC721Base();

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC721Implementation(implementationId, address(erc721base));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721base), block.number);
    }
}

contract MintTo is Script, Utils {
    function run(address _contractAddress, string memory _tokenURI) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        ERC721Base erc721Badge = ERC721Base(_contractAddress);
        erc721Badge.mintTo(deployerAddress, _tokenURI);

        vm.stopBroadcast();
    }
}

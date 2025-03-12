// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721BadgeNonTransferable} from "src/tokens/ERC721/ERC721BadgeNonTransferable.sol";
import {Globals} from "src/globals/Globals.sol";

string constant CONTRACT_NAME = "ERC721BadgeNonTransferable";
bytes32 constant implementationId = "BadgeNonTransferable";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721BadgeNonTransferable erc721BadgeNonTransferable = new ERC721BadgeNonTransferable(false);

        // add to globals
        Globals(getContractDeploymentAddress("Globals")).setERC721Implementation(implementationId, address(erc721BadgeNonTransferable));

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721BadgeNonTransferable), block.number);
    }
}

contract SetBaseURI is Script, Utils {
    function run(address _contractAddress, string memory _baseURIForTokens) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        ERC721BadgeNonTransferable erc721BadgeNonTransferable = ERC721BadgeNonTransferable(_contractAddress);
        erc721BadgeNonTransferable.setBaseURI(_baseURIForTokens);

        vm.stopBroadcast();
    }
}

contract MintTo is Script, Utils {
    function run(address _contractAddress) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        ERC721BadgeNonTransferable erc721BadgeNonTransferable = ERC721BadgeNonTransferable(_contractAddress);
        erc721BadgeNonTransferable.mintTo(deployerAddress);

        vm.stopBroadcast();
    }
}

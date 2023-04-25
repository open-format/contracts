// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {Globals} from "src/globals/Globals.sol";
import "forge-std/console.sol";

// TODO: deploy behind a upgradeable proxy see solidstate-solidity/contracts/proxy/upgradeable/UpgradeableProxyOwnable.sol
string constant CONTRACT_NAME = "Globals";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = new Globals();

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(globals), block.number);
    }
}

contract SetPlatformFee is Script, Utils {
    /**
     * @dev sets the platformFee to the given baseFee and recipient
     * @param baseFee fee in wei to set, use `cast --to-wei` to convert before calling
     * @param recipient the address all platform fees will be sent to
     */
    function run(uint256 baseFee, address recipient) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        Globals globals = Globals(getContractDeploymentAddress(CONTRACT_NAME));
        globals.setPlatformFee(baseFee, 0, recipient);

        vm.stopBroadcast();
    }
}

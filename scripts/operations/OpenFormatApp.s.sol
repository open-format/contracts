// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {AppFactory} from "src/factories/App.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";
import {CONTRACT_NAME as APP_FACTORY} from "scripts/core/AppFactory.s.sol";

string constant OPEN_FORMAT_APP = "Open_Format_App";
string constant OFT = "OFT";
string constant XP = "XP";

contract CreateApp is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);
        address appFactoryAddress = getContractDeploymentAddress(APP_FACTORY);

        if (appFactoryAddress == address(0)) {
           revert("Cannot find app factory deployment, make sure it is deployed");
        }

        // create open format app
        address openFormatApp = AppFactory(appFactoryAddress).create("Open Format App", deployerAddress);

        vm.stopBroadcast();

        exportContractDeployment(OPEN_FORMAT_APP, openFormatApp, block.number);
    }
}

contract DeployXP is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address openFormatApp = getContractDeploymentAddress(OPEN_FORMAT_APP);

        if (openFormatApp == address(0)) {
           revert("Cannot find open format app, make sure it is created");
        }

        vm.startBroadcast(deployerPrivateKey);

        // deploy XP
        address xp = ERC20FactoryFacet(openFormatApp).createERC20(
          "XP",
          "XP",
          18,
          0,
          "Base"
        );

        vm.stopBroadcast();

        exportContractDeployment(XP, xp, block.number);
    }
}

contract DeployOFT is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address openFormatApp = getContractDeploymentAddress(OPEN_FORMAT_APP);

        if (openFormatApp == address(0)) {
           revert("Cannot find open format app, make sure it is created");
        }

        vm.startBroadcast(deployerPrivateKey);

        // deploy OFT
        address oft = ERC20FactoryFacet(openFormatApp).createERC20(
          "Open Format Token",
          "OFT",
          18,
          100_000,
          "Base"
        );

        vm.stopBroadcast();

        exportContractDeployment(OFT, oft, block.number);
    }
}


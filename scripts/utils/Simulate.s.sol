// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {AppFactory} from "src/factories/App.sol";
import {ERC20FactoryFacet} from "src/facet/ERC20FactoryFacet.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {RewardsFacet} from "src/facet/RewardsFacet.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";
import {ERC20Point} from "src/tokens/ERC20/ERC20Point.sol";
import {ERC721Badge} from "src/tokens/ERC721/ERC721Badge.sol";

contract SimulateAppAndRewards is Script, Utils {
    function run(string memory appName) external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        bytes32 appNameBytes32 = vm.parseBytes32(appName);

        if (appNameBytes32.length == 0) {
            revert("please provide an app name, make CreateApp args=appName");
        }

        address app =
          AppFactory(getContractDeploymentAddress("AppFactory")).create(appNameBytes32, deployerAddress);

        //  create token
        address xp =
          ERC20FactoryFacet(app).createERC20("XP", "XP", 18, 10000000000000000000, "Base");

        //  create Point token
        address points =
          ERC20FactoryFacet(app).createERC20("Points", "Points", 18, 10000000000000000000, "Point");

        //  create badge
        address badge =
          ERC721FactoryFacet(app).createERC721WithTokenURI(
            "Novice Forager",
            "Novice Forager",
            "TokenURI",
            deployerAddress,
            1000,
            "Badge"
          );

        //  reward badge, reward token
        RewardsFacet(app).mintERC20(xp, deployerAddress, 100, "collected berry", "ACTION", "");
        RewardsFacet(app).mintERC20(points, deployerAddress, 100, "collected wood", "ACTION", "");
        RewardsFacet(app).mintBadge(badge, deployerAddress, "collected 10 berries", "MISSION", "");

        vm.stopBroadcast();

        console.log("App:", appName);
        console.log("App Address:", app);
        console.log("XP Address:", xp);
        console.log("Point Address:", points);
        console.log("Badge Address:", badge);
        console.log("XP balance:", ERC20Base(xp).balanceOf(deployerAddress));
        console.log("Point balance:", ERC20Point(points).balanceOf(deployerAddress));
        console.log("Badge balance:", ERC721Badge(badge).balanceOf(deployerAddress));
    }
}
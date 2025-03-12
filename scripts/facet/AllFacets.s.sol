// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {CONTRACT_NAME as REGISTRY} from "scripts/core/Registry.s.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Deployer as DeployerRewardsFacet} from "./RewardsFacet.s.sol";
import {Deployer as DeployerSettingsFacet} from "./SettingsFacet.s.sol";
import {Deployer as DeployerERC721FactoryFacet} from "./ERC721FactoryFacet.s.sol";
import {Deployer as DeployerERC721LazyDropFacet} from "./ERC721LazyDropFacet.s.sol";
import {Deployer as DeployerERC20FactoryFacet} from "./ERC20FactoryFacet.s.sol";
import {Deployer as DeployerChargeFacet} from "./ChargeFacet.s.sol";
import {IDeployer} from "./IDeployer.sol";

/**
 * Redeploys all the facet contracts
 * This script will first deploy new facet contracts, then calls an update transaction
 * known as a "diamond cut" that removes all existing facets and adds the newly deployed ones
 * to the registry contract.
 */
contract RedeployAllFacets is Script, Utils {
    /**
     * Will broadcast transactions and export contract addresses to deployed/<chain-id>.json
     */
    function run() external {
      address registryAddress = getContractDeploymentAddress(REGISTRY);
      _run(registryAddress, false);
    }

    /**
     * Will not broadcast any transactions so vm.prank can be used
     */
    function runTest(address registryAddress) external {
      _run(registryAddress, true);
    }

    function _run(address registryAddress, bool isTest) internal {

      // Initiate deployer scripts for all facets
      address[] memory deployers = new address[](6);
      deployers[0] = address(new DeployerRewardsFacet());
      deployers[1] = address(new DeployerSettingsFacet());
      deployers[2] = address(new DeployerERC721LazyDropFacet());
      deployers[3] = address(new DeployerERC721FactoryFacet());
      deployers[4] = address(new DeployerERC20FactoryFacet());
      deployers[5] = address(new DeployerChargeFacet());

      address[] memory facets = new address[](6);
      {
        // Deploy All facets contracts
        if (isTest){
          for (uint256 i = 0; i < deployers.length; i++) {
            facets[i] = IDeployer(deployers[i]).deployTest();
          }
        } else {
          for (uint256 i = 0; i < deployers.length; i++) {
            facets[i] = IDeployer(deployers[i]).deploy();
            IDeployer(deployers[i]).export();
          }
        }
      }

      // Perform a diamond cut that removes all facets then adds them back using the new deployment addresses
      {
        // Construct Diamond cut with new facets
        uint256 facetsToAdd = 6;
        IDiamondWritableInternal.FacetCut[] memory removeCuts = getRemoveCuts(registryAddress);
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](removeCuts.length + facetsToAdd);

        // Add cuts to `remove` all existing facets
        for (uint256 i = 0; i < removeCuts.length; i++){
          cuts[i] = removeCuts[i];
        }

        // Add cut to `add` each newly deployed facet
        for (uint256 i = 0; i < facets.length; i++) {
          cuts[removeCuts.length + i] = facetCutAdd(facets[i], IDeployer(deployers[i]).selectors());
        }

        // Perform the diamond cut
        if (isTest){
          // Use the default msg.sender in foundry tests
          // https://book.getfoundry.sh/reference/config/testing?highlight=0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38#sender
          vm.prank(address(0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38));
          IDiamondWritable(payable(registryAddress)).diamondCut(cuts, address(0), "");
        } else {
          uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
          address deployerAddress = vm.addr(deployerPrivateKey);
          vm.startBroadcast(deployerPrivateKey);
          IDiamondWritable(payable(registryAddress)).diamondCut(cuts, address(0), "");
          vm.stopBroadcast();
        }
      }
    }
}

contract RemoveAllFacets is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);

        address registryAddress = getContractDeploymentAddress(REGISTRY);
        IDiamondWritableInternal.FacetCut[] memory removeCuts = getRemoveCuts(registryAddress);

        vm.startBroadcast(deployerPrivateKey);

        IDiamondWritable(payable(registryAddress)).diamondCut(removeCuts, address(0), "");

        vm.stopBroadcast();
    }
}
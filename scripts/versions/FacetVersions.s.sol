// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {CONTRACT_NAME as REGISTRY} from "scripts/core/Registry.s.sol";
import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {IVersionable} from "src/extensions/versionable/IVersionable.sol";

contract FacetVersions is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        address registryAddress = getContractDeploymentAddress(REGISTRY);
        address[] memory facetAddresses = IDiamondReadable(registryAddress).facetAddresses();
        string[] memory facetNames = new string[](facetAddresses.length);
        string[] memory facetVersions = new string[](facetAddresses.length);
        string[][] memory facetSelectors = new string[][](facetAddresses.length);

        for (uint256 i = 0; i < facetAddresses.length; i++) {
          bytes4[] memory selectors = IDiamondReadable(registryAddress).facetFunctionSelectors(facetAddresses[i]);
          string[] memory selectorsNames = new string[](selectors.length);
          
          for (uint256 j = 0; j < selectors.length; j++) {
            selectorsNames[j] = bytes4ToHexString(selectors[j]);
          }
          facetSelectors[i] = selectorsNames;
          
          // Registry contract is returned in results
          if ( facetAddresses[i] == registryAddress ) {
            facetNames[i] = "Registry";
            facetVersions[i] = "-";

          } else {
            facetVersions[i] = IVersionable(facetAddresses[i]).facetVersion();
            facetNames[i] = IVersionable(facetAddresses[i]).facetName();
          }
        }
        exportFacetsVersions(facetAddresses, facetNames, facetVersions, facetSelectors);
        vm.stopBroadcast();
    }
}
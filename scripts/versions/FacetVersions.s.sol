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
            facetNames[i] = getFacetName(facetAddresses[i]);
            facetVersions[i] = getFacetVersion(facetAddresses[i]);
          }
        }
        exportFacetsVersions(facetAddresses, facetNames, facetVersions, facetSelectors);
        vm.stopBroadcast();
    }

    // Helper function to retrieve facet version or fallback to "0.0.0"
    function getFacetVersion(address facetAddress) private returns (string memory) {
        try IVersionable(facetAddress).facetVersion() returns (string memory version) {
            return version;
        } catch {
            return "0.0.0";
        }
    }

    // Helper function to retrieve facet name
    function getFacetName(address facetAddress) private returns (string memory) {
        try IVersionable(facetAddress).facetName() returns (string memory name) {
            return name;
        } catch {
            return getNameFromDeploymentFile(facetAddress);
        }
    }

    // Attempt to find name from deployment file or fallback to "Unknown-<address>"
    function getNameFromDeploymentFile(address facetAddress) private returns (string memory) {
        string memory facetName = getContractDeploymentName(facetAddress);

        if(bytes(facetName).length == 0){
          return string(abi.encodePacked("Unknown-", vm.toString(facetAddress)));
        }

        return facetName;
    }
}
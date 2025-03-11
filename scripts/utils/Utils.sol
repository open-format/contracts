pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

contract Utils is Script {
    error Utils_contractAddressNotFound(string contractName);
    error Utils_contractNameNotFound(address contractAddress);

    string constant namesKey = "doNotRemoveUsedToParseFile";

    string[] contractNames;
    string tempContractJson;

    function getContractDeploymentAddress(string memory contractName) internal returns (address) {
        string memory deploymentFile = _readDeploymentFile();
        bytes memory contractAddress = vm.parseJson(deploymentFile, string.concat(".", contractName, ".address"));
        if (contractAddress.length == 0) {
            revert Utils_contractAddressNotFound(contractName);
        }
        return abi.decode(contractAddress, (address));
    }

    function getContractDeploymentName(address contractAddress) internal returns (string memory) {
        string memory deploymentFile = _readDeploymentFile();

        // get all contract names from that file
        string[] memory contractNames = abi.decode(vm.parseJson(deploymentFile, string.concat(".", namesKey)), (string[]));

        // search deployment file for contract address
        for (uint256 i = 0; i < contractNames.length; i++){
            bytes memory matchBytes = vm.parseJson(deploymentFile, string.concat(".", contractNames[i], ".address"));
            if (matchBytes.length == 0){
                continue;
            }

            address matchAddress = abi.decode(matchBytes, (address));
            if (matchAddress == contractAddress){
                return contractNames[i];
            }
        }

        return "";
    }

    function exportFacetsVersions(address[] memory facetAddresses, string[] memory facetNames, string[] memory facetVersions, string[][] memory facetSelectors) 
        internal
    {
        string memory path = _getVersionsFilePath();
        string memory versionsJson;
        string memory allFacetsJson;
        string memory facetJson;

        for (uint256 i = 0; i < facetAddresses.length; i++) {
            facetJson = "";
            facetJson = vm.serializeAddress(facetNames[i], "address", facetAddresses[i]);
            facetJson = vm.serializeString(facetNames[i], "version", facetVersions[i]);
            facetJson = vm.serializeString(facetNames[i], "selectors", facetSelectors[i]);

            allFacetsJson = vm.serializeString("Facets", facetNames[i], facetJson);
        }
        versionsJson = vm.serializeString("json", "Facets", allFacetsJson);
        vm.writeJson(versionsJson, path);
    }

    function exportContractDeployment(string memory _contractName, address _contractAddress, uint256 _startBlock)
        internal
    {
        string memory path = _getDeployedFilePath();

        // serialize json
        string memory contractJson;
        contractJson = vm.serializeAddress(_contractName, "address", _contractAddress);
        contractJson = vm.serializeUint(_contractName, "startBlock", _startBlock);

        string memory deploymentFile = _readDeploymentFile();
        bool fileExists = bytes(deploymentFile).length > 0;
        bool isInJsonFile =
            fileExists ? (vm.parseJson(deploymentFile, string.concat(".", _contractName))).length > 0 : false;
        if (isInJsonFile) {
            // just update existing deployment address
            vm.writeJson(contractJson, path, string.concat(".", _contractName));
            return;
        }

        // wrap the address and startBlock with contract name
        contractJson = vm.serializeString("json", _contractName, contractJson);

        if (fileExists) {
            // get all contract names from that file
            contractNames = abi.decode(vm.parseJson(deploymentFile, string.concat(".", namesKey)), (string[]));
            // parse and reconstruct entire file
            for (uint256 i = 0; i < contractNames.length; i++) {
                (address contractAddress, uint256 startBlock) =
                    abi.decode(vm.parseJson(deploymentFile, string.concat(".", contractNames[i])), (address, uint256));
                tempContractJson = "";
                tempContractJson = vm.serializeAddress(contractNames[i], "address", contractAddress);
                tempContractJson = vm.serializeUint(contractNames[i], "startBlock", startBlock);

                contractJson = vm.serializeString("json", contractNames[i], tempContractJson);
            }
        } else {
            // no deployments exist so ensure array is empty
            delete contractNames;
        }

        // add the contractNames array with new contract name
        contractNames.push(_contractName);
        contractJson = vm.serializeString("json", namesKey, contractNames);

        // overwrite json file
        vm.writeJson(contractJson, path);
    }

    function _getDeployedFilePath() internal view returns (string memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/deployed/");
        string memory file = isStaging() ?
            string.concat(vm.toString(block.chainid), "-staging.json") :
            string.concat(vm.toString(block.chainid), ".json");

        return string.concat(inputDir, file);
    }

    function _getVersionsFilePath() internal view returns (string memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/deployed/");
        string memory file = isStaging() ?
            string.concat(vm.toString(block.chainid), "-staging.versions.json") :
            string.concat(vm.toString(block.chainid), ".versions.json");

        return string.concat(inputDir, file);
    }

    function _readDeploymentFile() internal returns (string memory) {
        try vm.readFile(_getDeployedFilePath()) returns (string memory result) {
            return result;
        } catch {
            return "";
        }
    }

    function isStaging () internal view returns (bool) {
        try vm.envBool("IS_STAGING") returns (bool value) {
            return value;
        } catch {
            return false;
        }
    }

    function bytes4ToHexString(bytes4 input) public pure returns (string memory) {
        bytes memory buffer = new bytes(10); // "0x" + 8 hex characters = 10 bytes
        buffer[0] = "0";
        buffer[1] = "x";

        for (uint256 i = 0; i < 4; i++) {
            uint8 b = uint8(input[i]);
            buffer[2 + i * 2] = _toHexChar(b >> 4); // First hex character
            buffer[3 + i * 2] = _toHexChar(b & 0x0f); // Second hex character
        }

        return string(buffer);
    }

    function _toHexChar(uint8 value) private pure returns (bytes1) {
        return value < 10 ? bytes1(value + 48) : bytes1(value + 87); // 0-9 => '0'-'9', 10-15 => 'a'-'f'
    }

    /**
     * Create an "add" facet diamond cut.
     */
    function facetCutAdd(address target, bytes4[] memory selectors) internal pure returns (IDiamondWritableInternal.FacetCut memory) {
      return IDiamondWritableInternal.FacetCut(target, IDiamondWritableInternal.FacetCutAction.ADD, selectors);
    }

    /**
     * Construct the 'diamond cuts' to remove all facets and selectors except those found on the registry contract
     */
    function getRemoveCuts(address registryAddress) internal view returns (IDiamondWritableInternal.FacetCut[] memory) {
        IDiamondReadable.Facet[] memory facets = IDiamondReadable(registryAddress).facets();
        //`facets.length -1` accounts for registry facet being returned from `facets` function above
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](facets.length - 1);
        uint256 cutCount = 0;
        for (uint256 i = 0; i < facets.length; i++) {
            // Registry facet selectors are imitable so it will revert if removal is attempted.
            if (facets[i].target == registryAddress) {
                continue;
            }

            cuts[cutCount] = IDiamondWritableInternal.FacetCut(
                address(0), IDiamondWritableInternal.FacetCutAction.REMOVE, facets[i].selectors
            );

            cutCount++;
        }

        return cuts;
    }
}

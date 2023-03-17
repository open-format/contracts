pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Utils is Script {
    error Utils_contractAddressNotFound(string contractName);

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
        bool isInJsonFile = fileExists ? (vm.parseJson(deploymentFile, _contractName)).length > 0 : false;

        if (isInJsonFile) {
            // just update existing deployment address
            vm.writeJson(contractJson, path, string.concat(".", _contractName));
            return;
        }

        // wrap the address and startBlock with contract name
        contractJson = vm.serializeString("json", _contractName, contractJson);

        if (fileExists) {
            // get all contract names from that file
            contractNames = abi.decode(vm.parseJson(deploymentFile, namesKey), (string[]));
            // parse and reconstruct entire file
            for (uint256 i = 0; i < contractNames.length; i++) {
                (address contractAddress, uint256 startBlock) =
                    abi.decode(vm.parseJson(deploymentFile, contractNames[i]), (address, uint256));
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

    function _getDeployedFilePath() internal returns (string memory) {
        string memory inputDir = string.concat(vm.projectRoot(), "/deployed/");
        string memory file = string.concat(vm.toString(block.chainid), ".json");

        return string.concat(inputDir, file);
    }

    function _readDeploymentFile() internal returns (string memory) {
        try vm.readFile(_getDeployedFilePath()) returns (string memory result) {
            return result;
        } catch {
            return "";
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC20FactoryFacet, ERC20Factory} from "src/facet/ERC20FactoryFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {IDeployer} from "./IDeployer.sol";

string constant CONTRACT_NAME = "ERC20FactoryFacet";

contract Deployer is IDeployer, Script, Utils {
    address private addr;
    uint256 private blockNumber;

    function deploy() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address erc20FactoryFacet = address(new ERC20FactoryFacet());
        vm.stopBroadcast();

        addr = erc20FactoryFacet;
        blockNumber = block.number;

        return erc20FactoryFacet;
    }

    function deployTest() external returns (address) {
        return address(new ERC20FactoryFacet());
    }

    function export() external {
        exportContractDeployment(CONTRACT_NAME, addr, blockNumber);
    }

    function selectors () external returns (bytes4[] memory){
        bytes4[] memory s = new bytes4[](3);
        s[0] = ERC20Factory.createERC20.selector;
        s[1] = ERC20Factory.getERC20FactoryImplementation.selector;
        s[2] = ERC20Factory.calculateERC20FactoryDeploymentAddress.selector;

        return s;
    }
}

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC20FactoryFacet erc20FactoryFacet = new ERC20FactoryFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = erc20FactoryFacet.createERC20.selector;
        selectors[1] = erc20FactoryFacet.getERC20FactoryImplementation.selector;
        selectors[2] = erc20FactoryFacet.calculateERC20FactoryDeploymentAddress.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc20FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc20FactoryFacet), block.number);
    }
}

contract Create is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        ERC20FactoryFacet erc20FactoryFacet = ERC20FactoryFacet(appId);

        erc20FactoryFacet.createERC20("TEST", "TEST", 18, 1000, "Base");

        vm.stopBroadcast();
    }
}

contract Update is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy new facet
        ERC20FactoryFacet erc20FactoryFacet = new ERC20FactoryFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = erc20FactoryFacet.createERC20.selector;
        selectors[1] = erc20FactoryFacet.getERC20FactoryImplementation.selector;
        selectors[2] = erc20FactoryFacet.calculateERC20FactoryDeploymentAddress.selector;

        // construct and REPLACE facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc20FactoryFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, selectors
        );

        // replace on registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        // update new address
        exportContractDeployment(CONTRACT_NAME, address(erc20FactoryFacet), block.number);
    }
}

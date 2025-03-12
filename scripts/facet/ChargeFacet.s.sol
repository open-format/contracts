// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ChargeFacet, Charge} from "src/facet/ChargeFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";
import {IDeployer} from "./IDeployer.sol";

string constant CONTRACT_NAME = "ChargeFacet";

contract Deployer is IDeployer, Script, Utils {
    address private addr;
    uint256 private blockNumber;

    function deploy() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address chargeFacet = address(new ChargeFacet());
        vm.stopBroadcast();

        addr = chargeFacet;
        blockNumber = block.number;

        return chargeFacet;
    }

    function deployTest() external returns (address) {
        return address(new ChargeFacet());
    }

    function export() external {
        exportContractDeployment(CONTRACT_NAME, addr, blockNumber);
    }

    function selectors () external returns (bytes4[] memory){
        bytes4[] memory s = new bytes4[](4);
        s[0] = Charge.chargeUser.selector;
        s[1] = Charge.setRequiredTokenBalance.selector;
        s[2] = Charge.getRequiredTokenBalance.selector;
        s[3] = Charge.hasFunds.selector;

        return s;
    }
}

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ChargeFacet chargeFacet = new ChargeFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = chargeFacet.chargeUser.selector;
        selectors[1] = chargeFacet.setRequiredTokenBalance.selector;
        selectors[2] = chargeFacet.getRequiredTokenBalance.selector;
        selectors[3] = chargeFacet.hasFunds.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(chargeFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(chargeFacet), block.number);
    }
}

contract Update is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ChargeFacet chargeFacet = new ChargeFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = chargeFacet.chargeUser.selector;
        selectors[1] = chargeFacet.setRequiredTokenBalance.selector;
        selectors[2] = chargeFacet.getRequiredTokenBalance.selector;
        selectors[3] = chargeFacet.hasFunds.selector;

        // construct and REPLACE facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(chargeFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(chargeFacet), block.number);
    }
}

contract ChargeUser is Script, Utils {
    function run(address user, address token, uint256 amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        ChargeFacet chargeFacet = ChargeFacet(appId);
        chargeFacet.chargeUser(user, token, amount, "OFT-001", "batch");
        vm.stopBroadcast();
    }
}

contract SetRequiredTokenBalance is Script, Utils {
    function run(address token, uint256 balance) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        ChargeFacet chargeFacet = ChargeFacet(appId);
        chargeFacet.setRequiredTokenBalance(token, balance);
        vm.stopBroadcast();
    }
}

contract HasFunds is Script, Utils {
    function run(address user, address token) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        ChargeFacet chargeFacet = ChargeFacet(appId);
        chargeFacet.hasFunds(user, token);
        vm.stopBroadcast();
    }
}

/**
 * @dev updates charge facet to use tokens naming convention instead of credits
 * @dev should only be run on staging env
 */
contract Update_useTokensNamingConvention is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ChargeFacet chargeFacet = new ChargeFacet();

        // construct array of function selectors to remove
        bytes4[] memory removeSelectors = new bytes4[](2);
        removeSelectors[0] = bytes4(keccak256(bytes("setMinimumCreditBalance(address,uint256)")));
        removeSelectors[1] = bytes4(keccak256(bytes("getMinimumCreditBalance(address)")));

        // construct array of function selectors to add
        bytes4[] memory addSelectors = new bytes4[](2);
        addSelectors[0] = chargeFacet.setRequiredTokenBalance.selector;
        addSelectors[1] = chargeFacet.getRequiredTokenBalance.selector;

        // construct array of function selectors to replace
        bytes4[] memory replaceSelectors = new bytes4[](2);
        replaceSelectors[0] = chargeFacet.chargeUser.selector;
        replaceSelectors[1] = chargeFacet.hasFunds.selector;

        // construct the facet cuts
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](3);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(0), IDiamondWritableInternal.FacetCutAction.REMOVE, removeSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(chargeFacet), IDiamondWritableInternal.FacetCutAction.ADD, addSelectors
        );
        cuts[2] = IDiamondWritableInternal.FacetCut(
            address(chargeFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(chargeFacet), block.number);
    }
}
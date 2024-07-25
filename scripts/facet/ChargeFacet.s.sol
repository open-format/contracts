// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ChargeFacet} from "src/facet/ChargeFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "ChargeFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ChargeFacet chargeFacet = new ChargeFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = chargeFacet.chargeUser.selector;
        selectors[1] = chargeFacet.setMinimumCreditBalance.selector;
        selectors[2] = chargeFacet.getMinimumCreditBalance.selector;
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
        selectors[1] = chargeFacet.setMinimumCreditBalance.selector;
        selectors[2] = chargeFacet.getMinimumCreditBalance.selector;
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
    function run(address user, address credit, uint256 amount) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        ChargeFacet chargeFacet = ChargeFacet(appId);
        chargeFacet.chargeUser(user, credit, amount, "OFT-001", "batch");
        vm.stopBroadcast();
    }
}

contract SetMinimumCreditBalance is Script, Utils {
    function run(address credit, uint256 balance) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        ChargeFacet chargeFacet = ChargeFacet(appId);
        chargeFacet.setMinimumCreditBalance(credit, balance);
        vm.stopBroadcast();
    }
}

contract HasFunds is Script, Utils {
    function run(address user, address credit) public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.addr(deployerPrivateKey);
        address appId = vm.envAddress("APP_ID");

        vm.startBroadcast(deployerPrivateKey);
        ChargeFacet chargeFacet = ChargeFacet(appId);
        chargeFacet.hasFunds(user, credit);
        vm.stopBroadcast();
    }
}

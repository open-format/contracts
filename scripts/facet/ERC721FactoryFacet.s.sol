// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";
import {Utils} from "scripts/utils/Utils.sol";
import {ERC721FactoryFacet} from "src/facet/ERC721FactoryFacet.sol";
import {RegistryMock} from "src/registry/RegistryMock.sol";

string constant CONTRACT_NAME = "ERC721FactoryFacet";

contract Deploy is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy
        ERC721FactoryFacet erc721FactoryFacet = new ERC721FactoryFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.createERC721WithTokenURI.selector;
        selectors[2] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        selectors[3] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

        // construct and ADD facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, selectors
        );

        // add to registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        exportContractDeployment(CONTRACT_NAME, address(erc721FactoryFacet), block.number);
    }
}

contract CreateBase is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        ERC721FactoryFacet erc721FactoryFacet = ERC721FactoryFacet(appId);

        erc721FactoryFacet.createERC721("TEST", "TEST", address(0x1), 1000, "Base");

        vm.stopBroadcast();
    }
}

contract CreateBadge is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        ERC721FactoryFacet erc721FactoryFacet = ERC721FactoryFacet(appId);

        erc721FactoryFacet.createERC721WithTokenURI("TEST", "TEST", "TokenURI", address(0x1), 1000, "Badge");

        vm.stopBroadcast();
    }
}

contract CreateBadgeNonTransferable is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        ERC721FactoryFacet erc721FactoryFacet = ERC721FactoryFacet(appId);

        erc721FactoryFacet.createERC721WithTokenURI("TEST", "TEST", "TokenURI", address(0x1), 1000, "BadgeNonTransferable");

        vm.stopBroadcast();
    }
}

contract Update is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy new facet
        ERC721FactoryFacet erc721FactoryFacet = new ERC721FactoryFacet();

        // construct array of function selectors
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.createERC721WithTokenURI.selector;
        selectors[2] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        selectors[3] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

        // construct and REPLACE facet cut
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, selectors
        );

        // replace on registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        // update new address
        exportContractDeployment(CONTRACT_NAME, address(erc721FactoryFacet), block.number);
    }
}

/**
 * @dev use this script to update deployments previous to PR #122  https://github.com/open-format/contracts/pull/122
 */
contract Update_Add_createERC721WithTokenURI is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy new facet
        ERC721FactoryFacet erc721FactoryFacet = new ERC721FactoryFacet();

        // function selectors to add
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = erc721FactoryFacet.createERC721WithTokenURI.selector;

        // function selectors to replace
        bytes4[] memory replaceSelectors = new bytes4[](3);
        replaceSelectors[0] = erc721FactoryFacet.createERC721.selector;
        replaceSelectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        replaceSelectors[2] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

        // construct facet cuts
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](2);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, addSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );

        // replace on registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        // update new address
        exportContractDeployment(CONTRACT_NAME, address(erc721FactoryFacet), block.number);
    }
}

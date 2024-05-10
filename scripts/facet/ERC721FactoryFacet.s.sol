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
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        selectors[2] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

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

contract Create is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        ERC721FactoryFacet erc721FactoryFacet = ERC721FactoryFacet(appId);

        erc721FactoryFacet.createERC721("TEST", "TEST", "", address(0x1), 1000, "Base");

        vm.stopBroadcast();
    }
}

contract CreateBadge is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address appId = vm.envAddress("APP_ID");
        vm.startBroadcast(deployerPrivateKey);

        ERC721FactoryFacet erc721FactoryFacet = ERC721FactoryFacet(appId);

        erc721FactoryFacet.createERC721("TEST", "TEST", "testBaseURI", address(0x1), 1000, "Badge");

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
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = erc721FactoryFacet.createERC721.selector;
        selectors[1] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        selectors[2] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

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

interface IOldERC721Factory {
    function createERC721(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        bytes32 _implementationId
    ) external payable returns (address id);
}

contract UpdateAddBaseTokenURI is Script, Utils {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploy new facet
        ERC721FactoryFacet erc721FactoryFacet = new ERC721FactoryFacet();

        bytes4 s = IOldERC721Factory.createERC721.selector;
        console.logBytes4(s);

        // function selectors to remove
        bytes4[] memory removeSelectors = new bytes4[](1);
        removeSelectors[0] = IOldERC721Factory.createERC721.selector;

        // function selectors to add
        bytes4[] memory addSelectors = new bytes4[](1);
        addSelectors[0] = erc721FactoryFacet.createERC721.selector;

        // function selectors to replace
        bytes4[] memory replaceSelectors = new bytes4[](2);
        replaceSelectors[0] = erc721FactoryFacet.getERC721FactoryImplementation.selector;
        replaceSelectors[1] = erc721FactoryFacet.calculateERC721FactoryDeploymentAddress.selector;

        // construct facet cuts
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](3);
        cuts[0] = IDiamondWritableInternal.FacetCut(
            address(0), IDiamondWritableInternal.FacetCutAction.REMOVE, removeSelectors
        );
        cuts[1] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.ADD, addSelectors
        );
        cuts[2] = IDiamondWritableInternal.FacetCut(
            address(erc721FactoryFacet), IDiamondWritableInternal.FacetCutAction.REPLACE, replaceSelectors
        );

        // replace on registry
        RegistryMock(payable(getContractDeploymentAddress("Registry"))).diamondCut(cuts, address(0), "");

        vm.stopBroadcast();

        // update new address
        exportContractDeployment(CONTRACT_NAME, address(erc721FactoryFacet), block.number);
    }
}

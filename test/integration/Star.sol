// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

// The following tests that proxy and registry contracts work together as intended

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {Proxy} from "../../src/proxy/Proxy.sol";
import {Upgradable} from "../../src/proxy/upgradable/Upgradable.sol";
import {RegistryMock} from "../../src/registry/RegistryMock.sol";
import {StarFactory} from "../../src/factories/Star.sol";
import {ConstellationFactory} from "src/factories/Constellation.sol";
import {ERC20Base} from "src/tokens/ERC20/ERC20Base.sol";

contract MessageFacet {
    string public message = "";

    function write(string memory _message) external {
        message = _message;
    }

    function read() external view returns (string memory) {
        return message;
    }
}

abstract contract Helpers {
    function prepareSingleFacetCut(
        address cutAddress,
        IDiamondWritableInternal.FacetCutAction cutAction,
        bytes4[] memory selectors
    ) public pure returns (IDiamondWritableInternal.FacetCut[] memory) {
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(cutAddress, cutAction, selectors);
        return cuts;
    }
}

contract Factory__intergration is Test, Helpers {
    StarFactory starFactory;
    ConstellationFactory constellationFactory;
    ERC20Base erc20Implementation;
    Proxy template;
    RegistryMock registry;
    MessageFacet message;

    // increase to simulate more proxies
    uint256 numberOfProxies = 2;

    function setUp() public {
        address globals = address(0); // TODO: add globals contract
        registry = new RegistryMock();
        template = new  Proxy(true);
        starFactory = new StarFactory(address(template), address(registry), globals);
        erc20Implementation = new ERC20Base();
        constellationFactory = new ConstellationFactory(address(erc20Implementation), address(globals));
        message = new MessageFacet();

        // add hello facet to registry
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = MessageFacet.write.selector;
        selectors[1] = MessageFacet.read.selector;
        registry.diamondCut(
            prepareSingleFacetCut(address(message), IDiamondWritableInternal.FacetCutAction.ADD, selectors),
            address(0),
            ""
        );
    }

    function test_factory_registry_is_correct() public {
        assertEq(starFactory.registry(), address(registry));
    }

    function test_factory_template_is_correct() public {
        assertEq(starFactory.template(), address(template));
    }

    function test_proxys_sketch() public {
        address constellation = constellationFactory.create("Constellation", "CSN", 18, 1000);

        address cloneAddress1 = starFactory.create(bytes32("saltyA"), address(constellation), address(0));
        address cloneAddress2 = starFactory.create(bytes32("saltyB"), address(constellation), address(0));

        // create instances
        Proxy clone1 = Proxy(payable(cloneAddress1));
        Proxy clone2 = Proxy(payable(cloneAddress2));
        assertEq(clone1.getRegistryAddress(), address(registry));
        assertEq(clone2.getRegistryAddress(), address(registry));

        MessageFacet(cloneAddress1).write("hello");
        assertEq(MessageFacet(cloneAddress1).read(), "hello");

        MessageFacet(cloneAddress2).write("world");
        assertEq(MessageFacet(cloneAddress2).read(), "world");

        // ensure no overiding is happening
        assertEq(MessageFacet(cloneAddress1).read(), "hello");
    }
}

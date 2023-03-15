// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "forge-std/Test.sol";
import {IProxy} from "../../src/proxy/IProxy.sol";
import {ProxyMock} from "../../src/proxy/ProxyMock.sol";

/**
 * @dev simple registry has a single function that returns bytes it received
 *      and a mock facetAddress function
 */
contract RegistryDummy {
    function dataReceived(bytes memory data) external pure returns (bytes memory) {
        return data;
    }

    function facetAddress(bytes4 selector) external view returns (address) {
        if (selector == bytes4(keccak256("dataReceived(bytes)"))) {
            return address(this);
        }

        return address(0);
    }
}

interface INotRegistered {
    function notRegistered() external;
}

contract Proxy__fallback is Test {
    address global = address(0); // TODO: add dummy global
    RegistryDummy registry;
    ProxyMock proxy;

    function setUp() public {
        registry = new RegistryDummy();
        proxy = new ProxyMock(address(registry), global);
    }

    function test_data_is_forwarded_to_implementation() public {
        bytes memory data = bytes("some bytes");
        bytes memory resp = RegistryDummy(address(proxy)).dataReceived(data);
        assertEq(keccak256(resp), keccak256(data));
    }

    function test_reverts_when_function_selector_is_not_found() public {
        vm.expectRevert(IProxy.Proxy_FunctionSelectorNotFound.selector);
        INotRegistered(address(proxy)).notRegistered();
    }
}

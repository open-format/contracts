// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

// The following tests that proxy and registry contracts work together as intended

import "forge-std/Test.sol";

import {
    IDiamondWritable,
    IDiamondWritableInternal
} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritable.sol";

import {ProxyMock} from "../../src/proxy/ProxyMock.sol";
import {RegistryMock} from "../../src/registry/RegistryMock.sol";

contract MessageFacet {
    // standardise namespacing
    bytes32 internal constant NAMESPACE = keccak256("message.facet");

    struct Storage {
        string message;
    }

    event MessageSet(string);

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;

        assembly {
            s.slot := position
        }
    }

    function setMessage(string calldata _msg) external {
        Storage storage s = getStorage();
        s.message = _msg;

        emit MessageSet(_msg);
    }

    function getMessage() external view virtual returns (string memory) {
        return getStorage().message;
    }
}

contract MessageFacetV2 is MessageFacet {
    // @dev override get message to append "-v2" to returned message
    function getMessage() external view override returns (string memory) {
        return string.concat(getStorage().message, "-v2");
    }
}

contract CorruptingMessageFacet {
    // same name space as MessageFacet
    bytes32 internal constant NAMESPACE = keccak256("message.facet");

    // the storage layout changes from a string to uint256
    struct Storage {
        uint256 message;
    }

    // the event changes from string to uint256
    event MessageSet(uint256);

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;

        assembly {
            s.slot := position
        }
    }

    // stores a uint256 instead of a string
    function setMessage(string calldata _msg) external {
        Storage storage s = getStorage();
        s.message = uint256(123);

        emit MessageSet(123);
    }

    // changing the function signiture from setMessage(string) to setMessage(uint256)
    // is caught when replacing the facet/function on the diamond
    // function setMessage(uint256 _msg) external {
    //     Storage storage s = getStorage();
    //     s.message = _msg;

    //     emit MessageSet(_msg);
    // }
}

// @dev stores multiple messages and timestamps
contract MessageFacetV3 {
    // standardise namespacing
    bytes32 internal constant NAMESPACE = keccak256("message.facet.v3");

    struct OldStorage {
        string message;
    }

    struct Message {
        string content;
        uint256 timestamp;
    }

    struct Storage {
        Message[] messages;
    }

    function getOldStorage() internal pure returns (OldStorage storage s) {
        bytes32 position = keccak256("message.facet");

        assembly {
            s.slot := position
        }
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;

        assembly {
            s.slot := position
        }
    }

    function migrateFromV1() external {
        OldStorage storage os = getOldStorage();
        Storage storage s = getStorage();

        if (bytes(os.message).length > 0) {
            s.messages.push(Message(os.message, block.timestamp));

            // unsure if delete is worth it here as will cost gas
            delete os.message;
        }
    }

    function addMessage(string calldata _msg) external {
        Storage storage s = getStorage();
        s.messages.push(Message(_msg, block.timestamp));
    }

    function getMessages() external view virtual returns (Message[] memory) {
        return getStorage().messages;
    }
}

abstract contract Helpers is Test {
    function prepareSingleFacetCut(
        address cutAddress,
        IDiamondWritableInternal.FacetCutAction cutAction,
        bytes4[] memory selectors
    ) public pure returns (IDiamondWritableInternal.FacetCut[] memory) {
        IDiamondWritableInternal.FacetCut[] memory cuts = new IDiamondWritableInternal.FacetCut[](1);
        cuts[0] = IDiamondWritableInternal.FacetCut(cutAddress, cutAction, selectors);
        return cuts;
    }

    // @dev retruns zero address if cut action is remove
    function getCutAddress(address _facet, IDiamondWritableInternal.FacetCutAction cutAction)
        public
        pure
        returns (address)
    {
        return (cutAction == IDiamondWritableInternal.FacetCutAction.REMOVE) ? address(0) : address(_facet);
    }

    function prepareMessageFacetCuts(address _facet, IDiamondWritableInternal.FacetCutAction cutAction)
        public
        pure
        returns (IDiamondWritableInternal.FacetCut[] memory)
    {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = MessageFacet.setMessage.selector;
        selectors[1] = MessageFacet.getMessage.selector;

        address cutAddress = getCutAddress(_facet, cutAction);
        return prepareSingleFacetCut(cutAddress, cutAction, selectors);
    }

    function prepareMessageFacetV3Cuts(address _facet, IDiamondWritableInternal.FacetCutAction cutAction)
        public
        pure
        returns (IDiamondWritableInternal.FacetCut[] memory)
    {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = MessageFacetV3.addMessage.selector;
        selectors[1] = MessageFacetV3.getMessages.selector;
        selectors[2] = MessageFacetV3.migrateFromV1.selector;

        address cutAddress = getCutAddress(_facet, cutAction);
        return prepareSingleFacetCut(cutAddress, cutAction, selectors);
    }

    function prepareCorruptingFacetCuts(address _facet, IDiamondWritableInternal.FacetCutAction cutAction)
        public
        pure
        returns (IDiamondWritableInternal.FacetCut[] memory)
    {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = CorruptingMessageFacet.setMessage.selector;

        address cutAddress = getCutAddress(_facet, cutAction);
        return prepareSingleFacetCut(cutAddress, cutAction, selectors);
    }

    function generateStringFromSeed(string memory seed) public pure returns (string memory) {
        return vm.toString(keccak256(abi.encode(seed)));
    }
}

contract Proxy_and_Registry__intergration is Test, Helpers {
    event MessageSet(string);

    RegistryMock diamond;
    MessageFacet messageFacet;

    // increase to simulate more proxies
    uint256 numberOfProxies = 2;
    ProxyMock[] proxies = new ProxyMock[](numberOfProxies);
    string[] messages = new string[](numberOfProxies);

    function setUp() public {
        diamond = new RegistryMock();
        messageFacet = new MessageFacet();

        // add message facet to diamond
        diamond.diamondCut(
            prepareMessageFacetCuts(address(messageFacet), IDiamondWritableInternal.FacetCutAction.ADD),
            address(0),
            bytes("")
        );

        // add messages
        string memory genMessage = "testing-123";
        for (uint256 i = 0; i < proxies.length; i++) {
            // generate different message
            genMessage = generateStringFromSeed(genMessage);
            messages[i] = genMessage;

            // deploy new proxy
            proxies[i] = (new ProxyMock(payable(diamond), address(0))); //TODO: add globals instead of zero address

            // set message
            (bool ok,) = address(proxies[i]).call(abi.encodeWithSelector(MessageFacet.setMessage.selector, messages[i]));
            assertTrue(ok);
        }
    }

    function test_ProxyMock_message_is_stored_on_proxies() public {
        for (uint256 i = 0; i < proxies.length; i++) {
            string memory message = MessageFacet(address(proxies[i])).getMessage();
            assertEq(message, messages[i]);
        }
    }

    function test_Proxy_updating_facet_is_reflected_on_proxies() public {
        assertEq(MessageFacet.getMessage.selector, MessageFacetV2.getMessage.selector);

        // update facet
        MessageFacetV2 messageFacetV2 = new MessageFacetV2();
        diamond.diamondCut(
            prepareMessageFacetCuts(address(messageFacetV2), IDiamondWritableInternal.FacetCutAction.REPLACE),
            address(0),
            bytes("")
        );

        for (uint256 i = 0; i < proxies.length; i++) {
            string memory message = MessageFacet(address(proxies[i])).getMessage();
            string memory expected = string.concat(messages[i], "-v2");
            assertEq(message, expected);
        }
    }

    function test_Proxy_proxies_emit_events() public {
        for (uint256 i = 0; i < proxies.length; i++) {
            vm.expectEmit(true, false, false, true, address(proxies[i]));
            emit MessageSet(messages[i]);

            MessageFacet(address(proxies[i])).setMessage(messages[i]);
        }
    }

    function test_Proxy_state_migration() public {
        // remove v1 facets
        diamond.diamondCut(
            prepareMessageFacetCuts(address(messageFacet), IDiamondWritableInternal.FacetCutAction.REMOVE),
            address(0),
            bytes("")
        );

        // deploy v3
        MessageFacetV3 messageFacetV3 = new MessageFacetV3();

        diamond.diamondCut(
            prepareMessageFacetV3Cuts(address(messageFacetV3), IDiamondWritableInternal.FacetCutAction.ADD),
            address(0),
            bytes("")
        );

        for (uint256 i = 0; i < proxies.length; i++) {
            MessageFacetV3(address(proxies[i])).migrateFromV1();

            string memory firstMessage = MessageFacetV3(address(proxies[i])).getMessages()[0].content;
            assertEq(firstMessage, messages[i]);
        }
    }

    function test_ProxyMock_state_corruption() public {
        // replace setMessage on diamond
        CorruptingMessageFacet corruptingMessageFacet = new CorruptingMessageFacet();
        diamond.diamondCut(
            prepareCorruptingFacetCuts(address(corruptingMessageFacet), IDiamondWritableInternal.FacetCutAction.REPLACE),
            address(0),
            bytes("")
        );
        for (uint256 i = 0; i < proxies.length; i++) {
            // corruptingMessageFacet.setMessage ignores input and sets value to uint256(123)
            CorruptingMessageFacet(address(proxies[i])).setMessage(messages[i]);

            (bool ok, bytes memory resp) =
                address(proxies[i]).call(abi.encodeWithSelector(MessageFacet.getMessage.selector));
            assertTrue(ok);

            // the result is niether the uint256 or string we expect
            bool isOldMessage = (keccak256(resp) == keccak256(abi.encode(messages[i])));
            assertFalse(isOldMessage);

            bool isNumber123 = (keccak256(resp) == keccak256(abi.encode(uint256(123))));
            assertFalse(isNumber123);
        }
    }
}

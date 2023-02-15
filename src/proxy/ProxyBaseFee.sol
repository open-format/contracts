// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IDiamondReadable} from "@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol";
import {SafeOwnable, OwnableInternal} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";
import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";

import {IProxy} from "./IProxy.sol";
import {Readable} from "./readable/Readable.sol";
import {Upgradable} from "./upgradable/Upgradable.sol";
import {Global} from "../extensions/global/Global.sol";
import {Initializable} from "../extensions/initializable/Initializable.sol";
import {BaseFee} from "../extensions/baseFee/BaseFee.sol";

/**
 * @title   "Open Format Proxy" contract
 * @notice  used to interact with open-format
 * @dev     is intended to not to be called directly but via a minimal proxy https://eips.ethereum.org/EIPS/eip-1167
 */
contract ProxyBaseFee is IProxy, Readable, Upgradable, Global, ERC165Base, Initializable, SafeOwnable, BaseFee {
    /// @param _disable disables initilizers, mainly used for testing and should be set to true in production
    constructor(bool _disable) {
        // As this contract is intended to be called from minimal proxy contracts
        // lock contract on deployment
        if (_disable) {
            _disableInitializers();
        }
    }

    /// @dev to be called on each clone as soon as possible
    function init(address _owner, address _registry, address _globals) public initializer {
        _setOwner(_owner);
        _setRegistryAddress(_registry);
        _setGlobals(_globals);

        _setSupportsInterface(type(IDiamondReadable).interfaceId, true);
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC173).interfaceId, true);
    }

    /**
     * @notice looks up implementation address and delegate all calls to implementation contract
     * @dev reverts if function selector is not in registry
     * @dev memory location in use by assembly may be unsafe in other contexts
     * @dev assembly code derived from @solidstate/contracts/proxy/Proxy.sol
     */

    // slither-disable-next-line locked-ether
    fallback() external payable {
        // TODO: ideally this comes after delegate call
        _applyBaseFee();

        address facet = _facetAddress(msg.sig);
        if (facet == address(0)) revert Error_FunctionSelectorNotFound();

        // slither-disable-next-line assembly
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    // withdraw functionality can be in a facet
    // slither-disable-next-line locked-ether
    receive() external payable {}

    function _transferOwnership(address account) internal virtual override(SafeOwnable) {
        super._transferOwnership(account);
    }

    // TODO: could be converted to modifier if we change the delgate call above to not return
    function _applyBaseFee() internal {
        // Hack attempts to determine view/pure call and avoid the need to charge base fee
        // See https://ethereum.stackexchange.com/questions/121510/detect-call-view-pure-execution-mode
        // See https://twitter.com/0xkarmacoma/status/1493380279309717505
        if (msg.sender == address(0) || gasleft() <= 1) {
            return;
        }

        (uint256 baseFee, address payable reciever) = _getBaseFeeInfo();
        require(baseFee <= msg.value, "must pay base fee");

        if (baseFee > 0) {
            // TODO: investigate reentrancy vulnerabilities
            // recommended way to send ether https://solidity-by-example.org/sending-ether/
            (bool ok,) = reciever.call{value: baseFee}("");
            require(ok, "failed to send base fee");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {MinimalProxyFactory} from "@solidstate/contracts/factory/MinimalProxyFactory.sol";

import {IConstellation} from "./IConstellation.sol";
import {ERC20Base} from "../tokens/ERC20/ERC20Base.sol";
import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

/**
 * @title "Constellation Factory"
 * @notice  A contract for creating ERC20 (constellation) contracts.
 *          This contract deploys minimal proxies that point to a Proxy implementation/template
 *          and is designed to be deployed separately from the registry and managed by Open Format.
 */
contract ConstellationFactory is IConstellation, MinimalProxyFactory, Ownable {
    address public globals;
    address public template;

    // store created constellations
    mapping(bytes32 => address) public constellations; // salt => deployment address

    constructor(address _template, address _globals) {
        _setOwner(msg.sender);
        template = _template;
        globals = _globals;
    }

    /**
     * @dev _salt param can be thought as the constellation id
     */
    function create(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply)
        external
        returns (address id)
    {
        bytes32 salt = keccak256(abi.encode(msg.sender, _name));

        // check constellation not already deployed
        if (constellations[salt] != address(0)) {
            revert Constellation_NameAlreadyUsed();
        }

        // deploy new constellation using CREATE2
        id = _deployMinimalProxy(template, salt);
        constellations[salt] = id;

        ERC20Base(payable(id)).initialize(msg.sender, _name, _symbol, _decimals, _supply, "");

        emit Created(id, msg.sender, string(abi.encodePacked(_name)));
    }

    function updateToken(string memory _name, address _oldTokenAddress, address _newTokenAddress) external {
        bytes32 salt = keccak256(abi.encode(msg.sender, _name));
        address oldTokenAddress = constellations[salt];

        if (oldTokenAddress == address(0)) {
            revert Constellation_NotFoundOrNotOwner();
        }

        // check _newTokenAddress address is a valid ERC20
        if (!IERC165(_newTokenAddress).supportsInterface(type(IERC20).interfaceId)) {
            revert Constellation_InvalidToken();
        }

        constellations[salt] = _newTokenAddress;

        emit UpdatedToken(_oldTokenAddress, _newTokenAddress);
    }

    /**
     * @notice returns the deterministic deployment address for constellation
     * @dev    The contract deployed is a minimal proxy pointing to the constellation template
     * @return deploymentAddress the address of the constellation
     */
    function calculateDeploymentAddress(address _account, bytes32 _name) external view returns (address) {
        bytes32 salt = keccak256(abi.encode(_account, _name));
        // check constellation not already deployed
        if (constellations[salt] != address(0)) {
            revert Constellation_NameAlreadyUsed();
        }

        return _calculateMinimalProxyDeploymentAddress(template, salt);
    }

    function setTemplate(address _template) public onlyOwner {
        template = _template;
    }

    function setGlobals(address _globals) public onlyOwner {
        globals = _globals;
    }
}

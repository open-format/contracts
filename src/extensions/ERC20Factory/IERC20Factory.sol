// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20Factory {
    event Created(address id, address creator, string _name, string _symbol, uint8 _decimals, uint256 _supply);

    function createERC20(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply)
        external
        returns (address id);

    function getERC20FactoryImplementation() external view returns (address);
}

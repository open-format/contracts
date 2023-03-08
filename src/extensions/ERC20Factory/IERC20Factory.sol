// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20Factory {
    error Error_do_not_have_permission();
    error Error_no_implementation_found();
    error Error_name_already_used();
    error Error_failed_to_initialize();

    event Created(address id, address creator, string _name, string _symbol, uint8 _decimals, uint256 _supply);

    function createERC20(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply)
        external
        returns (address id);

    function getERC20FactoryImplementation() external view returns (address);
}

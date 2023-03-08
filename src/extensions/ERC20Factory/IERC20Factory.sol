// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC20Factory {
    error Error_do_not_have_permission();
    error Error_no_implementation_found();
    error Error_name_already_used();
    error Error_failed_to_initialize();

    event Created(
        address id,
        address creator,
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes32 _implementationId
    );

    function createERC20(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes32 _implementationId
    ) external payable returns (address id);

    function getERC20FactoryImplementation(bytes32 _implementationId) external view returns (address);
}

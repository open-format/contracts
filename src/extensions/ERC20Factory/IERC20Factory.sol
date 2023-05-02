// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IERC20Factory {
    error ERC20Factory_doNotHavePermission();
    error ERC20Factory_noImplementationFound();
    error ERC20Factory_failedToInitialize();

    event Created(
        address id,
        address creator,
        string name,
        string symbol,
        uint8 decimals,
        uint256 supply,
        bytes32 implementationId
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

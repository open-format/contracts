// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC721Factory {
    event Created(
        address id,
        address creator,
        string name,
        string symbol,
        address royaltyRecipient,
        uint16 royaltyBps,
        bytes32 implementationId
    );

    function createERC721(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        bytes32 _implementationId
    ) external payable returns (address id);

    function getERC721FactoryImplementation(bytes32 _implementationId) external view returns (address);
}

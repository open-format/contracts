// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC721Factory {
    event Created(address id, address creator, string name, string symbol, address royaltyRecipient, uint16 royaltyBps);

    function createERC721(string memory _name, string memory _symbol, address _royaltyRecipient, uint16 _royaltyBps)
        external
        returns (address id);

    function getERC721FactoryImplementation() external view returns (address);
}

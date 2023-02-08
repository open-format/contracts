// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IERC721Factory {
    function createERC721(string memory _name, string memory _symbol, address _royaltyRecipient, uint16 _royaltyBps)
        external
        returns (address deployment);
    function getERC721FactoryImplementation() external view returns (address);
}

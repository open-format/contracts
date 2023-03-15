// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface ICompatibleERC721 {
    function owner() external returns (address);
    // if `owner()` is not implemented checks for DEFAULT_ADMIN_ROLE from access control `hasRole(0x00, msg.sender);`
    function hasRole(bytes32 role, address account) external returns (bool);

    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    // TODO: make ERC agnostic by removing these
    function mintTo(address _to) external;
    function batchMintTo(address _to, uint256 _quantity) external;
}

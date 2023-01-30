// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ERC721AUpgradeable} from "@erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";

abstract contract ERC721Base is ERC721AUpgradeable, Ownable {
    function __ERC721AMock_init(string memory name_, string memory symbol_) internal onlyInitializingERC721A {
        __ERC721A_init_unchained(name_, symbol_);
        _setOwner(msg.sender);
    }

    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }

    function totalMinted() public view returns (uint256) {
        return _totalMinted();
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned();
    }

    function nextTokenId() public view returns (uint256) {
        return _nextTokenId();
    }

    function getAux(address owner) public view returns (uint64) {
        return _getAux(owner);
    }

    function setAux(address owner, uint64 aux) public {
        _setAux(owner, aux);
    }

    function directApprove(address to, uint256 tokenId) public {
        _approve(to, tokenId);
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function safeMint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }

    function safeMint(address to, uint256 quantity, bytes memory _data) public {
        _safeMint(to, quantity, _data);
    }

    function mint(address to, uint256 quantity) public {
        _mint(to, quantity);
    }

    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }

    function burn(uint256 tokenId, bool approvalCheck) public {
        _burn(tokenId, approvalCheck);
    }

    function getOwnershipAt(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipAt(index);
    }

    function getOwnershipOf(uint256 index) public view returns (TokenOwnership memory) {
        return _ownershipOf(index);
    }
}

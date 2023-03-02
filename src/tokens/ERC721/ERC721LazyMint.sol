// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {AccessControl} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

import {ERC721AUpgradeable} from "@erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {Royalty} from "@extensions/royalty/Royalty.sol";
import {MintMetadata} from "@extensions/mintMetadata/MintMetadata.sol";
import {BatchMintMetadata} from "@extensions/batchMintMetadata/BatchMintMetadata.sol";
import {ContractMetadata, IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";
import {
    DefaultOperatorFilterer,
    DEFAULT_SUBSCRIPTION
} from "@extensions/defaultOperatorFilterer/DefaultOperatorFilterer.sol";
import {LazyMint} from "@extensions/lazyMint/LazyMint.sol";

contract ERC721LazyMint is
    ERC721AUpgradeable,
    AccessControl,
    ERC165BaseInternal,
    MintMetadata,
    BatchMintMetadata,
    ContractMetadata,
    DefaultOperatorFilterer,
    Royalty,
    Multicall,
    LazyMint
{
    event Minted(address to, string tokenURI);
    event BatchMinted(address to, uint256 quantity, string baseURI);

    bytes32 internal constant ADMIN_ROLE = bytes32(uint256(0));
    bytes32 internal constant MINTER_ROLE = bytes32(uint256(1));

    constructor(string memory _name, string memory _symbol, address _royaltyReciever, uint16 _royaltyBPS)
        payable
        initializerERC721A
    {
        initialize(msg.sender, _name, _symbol, _royaltyReciever, _royaltyBPS);
    }

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps
    ) public initializerERC721A {
        __ERC721A_init(_name, _symbol);
        _grantRole(ADMIN_ROLE, _owner);
        _setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);
        _registerToDefaultOperatorFilterer(DEFAULT_SUBSCRIPTION, true);

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
        _setSupportsInterface(0x5b5e139f, true); // ERC165 interface ID for ERC721Metadata
        _setSupportsInterface(type(IERC2981).interfaceId, true);
        _setSupportsInterface(type(IContractMetadata).interfaceId, true);
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev override ERC721AUpgradeable to use solidstates ERC165BaseInternal
     */

    function supportsInterface(bytes4 interfaceId) public view override(ERC721AUpgradeable, IERC165) returns (bool) {
        return _supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721A logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        // tokenURI was stored using mintTo
        string memory fullTokenURI = _getTokenURI(_tokenId);
        if (bytes(fullTokenURI).length > 0) {
            return fullTokenURI;
        }

        // tokenURI was stored using batchMintTo
        string memory batchUri = _getBaseURI(_tokenId);
        return string.concat(batchUri, UintUtils.toString(_tokenId));
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     */

    function mintTo(address _to) public virtual {
        require(_canMint(), "Not authorized to mint.");
        uint256 tokenId = _nextTokenId();
        require(tokenId < _getNextTokenIdToLazyMint(), "Not enough lazy minted tokens");

        _safeMint(_to, 1);

        emit Minted(_to, string.concat(_getBaseURI(tokenId), UintUtils.toString(tokenId)));
    }

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _quantity The number of NFTs to mint.
     */

    function batchMintTo(address _to, uint256 _quantity) public virtual {
        require(_canMint(), "Not authorized to mint.");
        require((_nextTokenId() + _quantity) - 1 < _getNextTokenIdToLazyMint(), "Not enough lazy minted tokens");

        string memory _baseURI = _getBaseURI(_nextTokenId());
        _safeMint(_to, _quantity);

        emit BatchMinted(_to, _quantity, _baseURI);
    }

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */

    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /*//////////////////////////////////////////////////////////////
                        Public getters
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return _nextTokenId();
    }

    /// @notice Returns whether a given address is the owner, or approved to transfer an NFT.
    function isApprovedOrOwner(address _operator, uint256 _tokenId)
        public
        view
        virtual
        returns (bool isApprovedOrOwnerOf)
    {
        address owner = ownerOf(_tokenId);
        isApprovedOrOwnerOf =
            (_operator == owner || isApprovedForAll(owner, _operator) || getApproved(_tokenId) == _operator);
    }

    /// @notice Returns whether a given token id has been minted
    function exists(uint256 _tokenId) external virtual returns (bool) {
        return _exists(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                        ERC-721A overrides
    //////////////////////////////////////////////////////////////*/

    /// @dev See {ERC721-setApprovalForAll}.
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender) || _hasRole(MINTER_ROLE, msg.sender);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetRoyaltyInfo() internal view virtual override returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender);
    }

    function _canLazyMint() internal view virtual override returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender);
    }
}
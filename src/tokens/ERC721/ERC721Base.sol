// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {ERC2981, ERC2981Storage} from "@solidstate/contracts/token/common/ERC2981/ERC2981.sol";
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";

import {ERC721AUpgradeable} from "@erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {BatchMintMetadata} from "./batchMintMetadata/BatchMintMetadata.sol";
import {ContractMetadata, IContractMetadata} from "./contractMetadata/ContractMetadata.sol";
import {DefaultOperatorFilterer, DEFAULT_SUBSCRIPTION} from "./defaultOperatorFilterer/DefaultOperatorFilterer.sol";

abstract contract ERC721Base is
    ERC721AUpgradeable,
    Ownable,
    ERC2981,
    ERC165BaseInternal,
    BatchMintMetadata,
    ContractMetadata,
    DefaultOperatorFilterer
{
    mapping(uint256 => string) private fullURI;

    function initialize(string memory _name, string memory _symbol, address _royaltyReciever, uint16 _royaltyBPS)
        public
        initializerERC721A
    {
        __ERC721A_init(_name, _symbol);
        _setOwner(msg.sender);
        _setRoyaltyDefault(_royaltyReciever, _royaltyBPS);
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
        string memory fullUriForToken = fullURI[_tokenId];
        if (bytes(fullUriForToken).length > 0) {
            return fullUriForToken;
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
     *  @param _tokenURI The full metadata URI for the NFT minted.
     */
    function mintTo(address _to, string memory _tokenURI) public virtual {
        require(_canMint(), "Not authorized to mint.");
        _setTokenURI(_nextTokenId(), _tokenURI);
        _safeMint(_to, 1);
    }

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _quantity The number of NFTs to mint.
     *  @param _baseURI  The baseURI for the `n` number of NFTs minted. The metadata for each NFT is `baseURI/tokenId`
     */

    function batchMintTo(address _to, uint256 _quantity, string memory _baseURI) public virtual {
        require(_canMint(), "Not authorized to mint.");
        _batchMintMetadata(_nextTokenId(), _quantity, _baseURI);
        _safeMint(_to, _quantity);
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

    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal virtual {
        require(bytes(fullURI[_tokenId]).length == 0, "URI already set");
        fullURI[_tokenId] = _tokenURI;
    }

    /**
     * @dev internal function to set the royalty receiver and amount in BPS
     */
    // TODO: refactor out into royalty extenstion that allows for seperate royalties per token
    function _setRoyaltyDefault(address defaultRoyaltyReceiver, uint16 defaultRoyaltyBPS) internal virtual {
        ERC2981Storage.Layout storage l = ERC2981Storage.layout();
        l.defaultRoyaltyBPS = defaultRoyaltyBPS;
        l.defaultRoyaltyReceiver = defaultRoyaltyReceiver;
    }

    function _canMint() internal view virtual returns (bool) {
        return msg.sender == _owner();
    }

    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == _owner();
    }
}

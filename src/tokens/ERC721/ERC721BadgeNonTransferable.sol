// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import "forge-std/Script.sol";

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IERC721} from "@solidstate/contracts/interfaces/IERC721.sol";
import {IERC2981} from "@solidstate/contracts/interfaces/IERC2981.sol";
import {AccessControl} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {ERC165BaseInternal} from "@solidstate/contracts/introspection/ERC165/base/ERC165BaseInternal.sol";
import {UintUtils} from "@solidstate/contracts/utils/UintUtils.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";

import {ERC721AUpgradeable} from "@erc721a-upgradeable/contracts/ERC721AUpgradeable.sol";

import {Royalty} from "@extensions/royalty/Royalty.sol";
import {BatchMintMetadata} from "@extensions/batchMintMetadata/BatchMintMetadata.sol";
import {ContractMetadata, IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";
import {Global} from "@extensions/global/Global.sol";
import {PlatformFee} from "@extensions/platformFee/PlatformFee.sol";

import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

string constant CONTRACT_VERSION = "0.1.0";
string constant CONTRACT_NAME = "ERC721BadgeNonTransferable";

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

uint256 constant MAX_INT = 2 ** 256 - 1;

contract ERC721BadgeNonTransferable is
    ERC721AUpgradeable,
    AccessControl,
    ERC165BaseInternal,
    ContractMetadata,
    BatchMintMetadata,
    Royalty,
    Multicall,
    Global,
    PlatformFee,
    ReentrancyGuard,
    Ownable
{
    error ERC721BadgeNonTransferable_notAuthorized();
    error ERC721BadgeNonTransferable_insufficientLazyMintedTokens();
    error ERC721BadgeNonTransferable_nonTransferable();

    event Minted(address to, string tokenURI);
    event BatchMinted(address to, uint256 quantity, string baseURI);
    event UpdatedBaseURI(string baseURIForTokens);
    event BatchMetadataUpdate(uint256 fromTokenId, uint256 toTokenId);

    /**
     * @dev this contract is meant to be an implementation for a factory contract
     *      calling initialize in constructor prevents the implementation from being used by third party
     * @param _isTest used to prevent the initialisation. Set to true in unit tests and false in production
     */
    constructor(bool _isTest) {
        if (!_isTest) {
            initialize(address(0), "", "", address(0), 0, "");
        }
    }

    /**
     * @dev initialize should be called from a trusted contract and not directly by an account.
     *      platform fee could easily be bypassed by not properly encoding data.
     *
     * @param _data bytes encoded with the signature (address,address,string)
     *              the first will be granted a minter role
     *              the second address will be set as the globals address
     *              used to calculate platform fees
     *              The string is the baseURI for all tokens on the contract
     */
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint16 _royaltyBps,
        bytes memory _data
    ) public virtual initializerERC721A {
        __ERC721A_init(_name, _symbol);
        _grantRole(ADMIN_ROLE, _owner);
        _setOwner(_owner);
        _setDefaultRoyaltyInfo(_royaltyRecipient, _royaltyBps);

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
        _setSupportsInterface(type(IERC2981).interfaceId, true);
        _setSupportsInterface(type(IContractMetadata).interfaceId, true);

        if (_data.length == 0) {
            return;
        }

        // decode data to app address and globals address
        (address app, address globals, string memory baseURIForTokens) = abi.decode(_data, (address, address, string));

        if (app != address(0)) {
            _grantRole(MINTER_ROLE, app);
        }

        if (globals != address(0)) {
            _setGlobals(globals);
        }

        if (bytes(baseURIForTokens).length > 0) {
            _batchMintMetadata(0, MAX_INT, baseURIForTokens);
            emit BatchMetadataUpdate(0, MAX_INT);
            emit UpdatedBaseURI(baseURIForTokens);
        }
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
        // tokenURI was stored using batchMintTo
        return _getBaseURI(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Lets an authorized address set base uri for all tokens
     * @param _baseURIForTokens the base URI to be set for all tokens
     *
     */
    function setBaseURI(string calldata _baseURIForTokens) public payable nonReentrant {
        if (!_canSetBaseURI()) {
            revert ERC721BadgeNonTransferable.ERC721BadgeNonTransferable_notAuthorized();
        }

        (address platformFeeRecipient, uint256 platformFeeAmount) = _checkPlatformFee();

        // there will only ever be a baseURICount of zero or one
        if (_getBaseURICount() > 0) {
            _setBaseURI(MAX_INT, _baseURIForTokens);
        } else {
            _batchMintMetadata(0, MAX_INT, _baseURIForTokens);
        }

        emit BatchMetadataUpdate(0, MAX_INT);
        emit UpdatedBaseURI(_baseURIForTokens);

        _payPlatformFee(platformFeeRecipient, platformFeeAmount);
    }

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     */
    function mintTo(address _to) public payable virtual nonReentrant {
        if (!_canMint()) {
            revert ERC721BadgeNonTransferable_notAuthorized();
        }

        (address platformFeeRecipient, uint256 platformFeeAmount) = _checkPlatformFee();

        uint256 tokenId = _nextTokenId();

        _safeMint(_to, 1);

        emit Minted(_to, _getBaseURI(tokenId));

        _payPlatformFee(platformFeeRecipient, platformFeeAmount);
    }

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _quantity The number of NFTs to mint.
     */
    function batchMintTo(address _to, uint256 _quantity) public payable virtual nonReentrant {
        if (!_canMint()) {
            revert ERC721BadgeNonTransferable_notAuthorized();
        }

        (address platformFeeRecipient, uint256 platformFeeAmount) = _checkPlatformFee();

        string memory _baseURI = _getBaseURI(_nextTokenId());
        _safeMint(_to, _quantity);

        emit BatchMinted(_to, _quantity, _baseURI);

        _payPlatformFee(platformFeeRecipient, platformFeeAmount * _quantity);
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
    function setApprovalForAll(address operator, bool approved) public override(ERC721AUpgradeable) {
        super.setApprovalForAll(operator, approved);
    }

    /// @dev See {ERC721-approve}.
    function approve(address operator, uint256 tokenId) public payable override(ERC721AUpgradeable) {
        super.approve(operator, tokenId);
    }

    /// @dev See {ERC721-_transferFrom}.
    function transferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable) {
        revert ERC721BadgeNonTransferable.ERC721BadgeNonTransferable_nonTransferable();
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable override(ERC721AUpgradeable) {
        revert ERC721BadgeNonTransferable.ERC721BadgeNonTransferable_nonTransferable();
    }

    /// @dev See {ERC721-_safeTransferFrom}.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        payable
        override(ERC721AUpgradeable)
    {
        revert ERC721BadgeNonTransferable.ERC721BadgeNonTransferable_nonTransferable();
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetBaseURI() internal view virtual returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender);
    }

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

    /*//////////////////////////////////////////////////////////////
                        Internal (platform fee) functions
    //////////////////////////////////////////////////////////////*/

    function _checkPlatformFee() internal view returns (address recipient, uint256 amount) {
        // don't charge platform fee if sender is a contract or globals address is not set
        if (_isContract(msg.sender) || _getGlobalsAddress() == address(0)) {
            return (address(0), 0);
        }

        (recipient, amount) = _platformFeeInfo(0);

        // ensure the ether being sent was included in the transaction
        if (amount > msg.value) {
            revert CurrencyTransferLib.CurrencyTransferLib_insufficientValue();
        }
    }

    function _payPlatformFee(address recipient, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        CurrencyTransferLib.safeTransferNativeToken(recipient, amount);

        emit PaidPlatformFee(address(0), amount);
    }

    /**
     * @dev derived from Openzepplin's address utils
     *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.2/contracts/utils/Address.sol
     */
    function _isContract(address _account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return _account.code.length > 0;
    }
}

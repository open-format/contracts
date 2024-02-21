// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {AccessControl} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";
import {IERC20BaseInternal} from "@solidstate/contracts/token/ERC20/base/IERC20BaseInternal.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";

import {HederaTokenService} from '@hashgraph/contracts/hts-precompile/HederaTokenService.sol';
import {IHederaTokenService} from '@hashgraph/contracts/hts-precompile/IHederaTokenService.sol';
import {ExpiryHelper} from '@hashgraph/contracts/hts-precompile/ExpiryHelper.sol';
import {KeyHelper} from '@hashgraph/contracts/hts-precompile/KeyHelper.sol';
import {HederaResponseCodes} from '@hashgraph/contracts/hts-precompile/HederaResponseCodes.sol';

import {ContractMetadata, IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";
import {Initializable} from "@extensions/initializable/Initializable.sol";
import {Global} from "@extensions/global/Global.sol";
import {PlatformFee} from "@extensions/platformFee/PlatformFee.sol";

import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

/**
 *  @dev Thirdweb inspired ERC20Base contract using solidstates ERC20 contract and diamond storage throughout.
 *       has the edition of ERC165
 *
 *  The `ERC20Base` smart contract implements the ERC20 standard.
 *  It includes the following additions to standard ERC20 logic:
 *
 *      - Ability to mint & burn tokens via the provided `mintTo` & `burn` functions.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2612 compliance: See {ERC20-permit} method, which can be used to change an account's ERC20 allowance by
 *                             presenting a message signed by the account.
 */

bytes32 constant ADMIN_ROLE = bytes32(uint256(0));
bytes32 constant MINTER_ROLE = bytes32(uint256(1));

contract ERC20Base is
    AccessControl,
    Multicall,
    ContractMetadata,
    Initializable,
    ERC165Base,
    Global,
    PlatformFee,
    ReentrancyGuard,
    HederaTokenService,
    ExpiryHelper,
    KeyHelper,
    IERC20BaseInternal
{
    error ERC20Base_notAuthorized();
    error ERC20Base_zeroAmount();
    error ERC20Base_insufficientBalance();
    error HTSFailedResponseCode(int256 code);

    // HTS Token this contract owns
    address private _tokenAddress;


    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes memory _data
    ) public initializer payable {
        _grantRole(ADMIN_ROLE, _owner);

        // Delegate key for this contract
        IHederaTokenService.KeyValue memory keyValue;
        keyValue.inheritAccountKey = false;
        keyValue.delegatableContractId = address(this);

        IHederaTokenService.TokenKey[] memory keys = new IHederaTokenService.TokenKey[](4);
        keys[0] = IHederaTokenService.TokenKey(1, keyValue);    // ADMIN
        keys[1] = IHederaTokenService.TokenKey(4, keyValue);    // FREEZE
        keys[2] = IHederaTokenService.TokenKey(16, keyValue);   // SUPPLY
        keys[3] = IHederaTokenService.TokenKey(8, keyValue);    // WIPE
        
        // Token expiration information
        IHederaTokenService.Expiry memory tokenExpiry;
        tokenExpiry.second = 0;
        tokenExpiry.autoRenewAccount = address(this);
        tokenExpiry.autoRenewPeriod = defaultAutoRenewPeriod;

        // Memo
        string memory tokenMemo = string(
            abi.encodePacked(_symbol,"@",AddressUtils.toString(address(this)))
        );

        // Token struct
        IHederaTokenService.HederaToken memory token = IHederaTokenService.HederaToken(
            _name, _symbol, address(this), tokenMemo, false, 0, false, keys, tokenExpiry
        );
        
        // Create token with initial supply
        (int responseCode, address tokenAddress) = 
        HederaTokenService.createFungibleToken(token, int64(uint64(_supply)), int32(uint32(_decimals)));
        _checkResponse(responseCode);

        _tokenAddress = tokenAddress;

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC20).interfaceId, true);
        _setSupportsInterface(type(IERC2612).interfaceId, true);
        _setSupportsInterface(type(IContractMetadata).interfaceId, true);

        if (_data.length == 0) {
            return;
        }

        // decode data to app address and globals address
        (address app, address globals) = abi.decode(_data, (address, address));

        if (app != address(0)) {
            _grantRole(MINTER_ROLE, app);
        }

        if (globals != address(0)) {
            _setGlobals(globals);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          Minting logic
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function balanceOf(address account) external view virtual returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(account);
    }

    /**
     *  @notice          Lets an authorized address mint tokens to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint tokens.
     *
     *  @param _to       The recipient of the tokens to mint.
     *  @param _amount   Quantity of tokens to mint.
     */
    function mintTo(address _to, uint256 _amount) public payable virtual nonReentrant {
        if (!_canMint()) {
            revert ERC20Base_notAuthorized();
        }

        if (_amount < 1) {
            revert ERC20Base_zeroAmount();
        }

        (address platformFeeRecipient, uint256 platformFeeAmount) = _checkPlatformFee();

        _mint(_to, _amount);

        _payPlatformFee(platformFeeRecipient, platformFeeAmount);
    }

    /**
     *  @notice          Lets an owner a given amount of their tokens.
     *  @dev             Caller should own the `_amount` of tokens.
     *
     *  @param _amount   The number of tokens to burn.
     */
    function burn(uint256 _amount) external virtual {
        if (_balanceOf(msg.sender) < _amount) {
            revert ERC20Base_insufficientBalance();
        }

        _burn(msg.sender, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                    Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether tokens can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender) || _hasRole(MINTER_ROLE, msg.sender);
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return _hasRole(ADMIN_ROLE, msg.sender);
    }

    /// @dev grants minter role if data is just an address
    function _grantMinterRoleFromData(bytes memory _data) internal virtual {
        if (_data.length == 0) {
            return;
        }

        (address account) = abi.decode(_data, (address));
        if (account != address(0)) {
            _grantRole(MINTER_ROLE, account);
        }
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

    /**
     * @dev Reverts transaction if response code is not SUCCESS
     *
     * @param code HTS response code
     */
    function _checkResponse(int code) internal pure returns (bool) {
        if (code != HederaResponseCodes.SUCCESS)
            revert HTSFailedResponseCode(code);
        return true;
    }

    /**
     * @notice mint tokens for given account
     * @param account recipient of minted tokens
     * @param amount quantity of tokens minted
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__MintToZeroAddress();

        (int responseCode, , ) = mintToken(_tokenAddress, int64(uint64(amount)), new bytes[](0));
        _checkResponse(responseCode);

        responseCode = transferToken(_tokenAddress, address(this), account, int64(uint64(amount)));
        _checkResponse(responseCode);

        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice burn tokens held by given account
     * @param account holder of burned tokens
     * @param amount quantity of tokens burned
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) revert ERC20Base__BurnFromZeroAddress();

        int code = transferToken(_tokenAddress, account, address(0), int64(uint64(amount)));
        _checkResponse(code);

        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice query the token balance of given account
     * @param account address to query
     * @return token balance
     */
    function _balanceOf(address account) internal view virtual returns (uint256) {
        return IERC20(_tokenAddress).balanceOf(account);
    }

    /**
     * @notice transfer tokens to given recipient on behalf of given holder
     * @param holder holder of tokens prior to transfer
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transferFrom( address holder, address recipient, uint256 amount) external returns (bool) {
        bool result = IERC20(_tokenAddress).transferFrom(holder, recipient, amount);
        emit Transfer(holder, recipient, amount);
        
        return result;
    }

    /**
     * @notice query the allowance granted from given holder to given spender
     * @param holder approver of allowance
     * @param spender recipient of allowance
     * @return token allowance
     */
    function allowance(address holder, address spender) external view returns (uint256) {
        return IERC20(_tokenAddress).allowance(holder, spender);
    }

    /**
     * @notice grant approval to spender to spend tokens
     * @dev prefer ERC20Extended functions to avoid transaction-ordering vulnerability (see https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729)
     * @param spender recipient of allowance
     * @param amount quantity of tokens approved for spending
     * @return success status (always true; otherwise function should revert)
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        return IERC20(_tokenAddress).approve(spender, amount);
    }

    /**
     * @notice query the total minted token supply
     * @return token supply
     */
    function totalSupply() external view returns (uint256) {
        return IERC20(_tokenAddress).totalSupply();
    }

    /**
     * @notice transfer tokens to given recipient
     * @param recipient beneficiary of token transfer
     * @param amount quantity of tokens to transfer
     * @return success status (always true; otherwise function should revert)
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        bool result = IERC20(_tokenAddress).transfer(recipient, amount);
        emit Transfer(address(this), recipient, amount);

        return result;
    }

    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory){
        return IERC20Metadata(_tokenAddress).name();
    }

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory){
        return IERC20Metadata(_tokenAddress).symbol();
    }

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8){
        return IERC20Metadata(_tokenAddress).decimals();
    }

}

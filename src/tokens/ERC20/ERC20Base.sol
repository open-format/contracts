// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";
import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {AccessControl} from "@solidstate/contracts/access/access_control/AccessControl.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {ReentrancyGuard} from "@solidstate/contracts/utils/ReentrancyGuard.sol";

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
    SolidStateERC20,
    AccessControl,
    Multicall,
    ContractMetadata,
    Initializable,
    ERC165Base,
    Global,
    PlatformFee,
    ReentrancyGuard
{
    error ERC20Base_notAuthorized();
    error ERC20Base_zeroAmount();
    error ERC20Base_insufficientBalance();

    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _supply,
        bytes memory _data
    ) public initializer {
        _grantRole(ADMIN_ROLE, _owner);

        _setName(_name);
        _setSymbol(_symbol);
        _setDecimals(_decimals);

        _mint(_owner, _supply);

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
}

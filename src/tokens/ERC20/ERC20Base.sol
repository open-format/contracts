// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

import {SolidStateERC20} from "@solidstate/contracts/token/ERC20/SolidStateERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

import {ERC165Base} from "@solidstate/contracts/introspection/ERC165/base/ERC165Base.sol";
import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";

import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";
import {ContractMetadata, IContractMetadata} from "@extensions/contractMetadata/ContractMetadata.sol";
import {Initializable} from "@extensions/initializable/Initializable.sol";

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

contract ERC20Base is SolidStateERC20, Ownable, Multicall, ContractMetadata, Initializable, ERC165Base {
    error ERC20Base_notAuthorized();
    error ERC20Base_zeroAmount();
    error ERC20Base_insufficientBalance();

    function initialize(address _owner, string memory _name, string memory _symbol, uint8 _decimals, uint256 supply)
        public
        initializer
    {
        _setOwner(_owner);

        _setName(_name);
        _setSymbol(_symbol);
        _setDecimals(_decimals);

        _mint(_owner, supply);

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC20).interfaceId, true);
        _setSupportsInterface(type(IERC2612).interfaceId, true);
        _setSupportsInterface(type(IContractMetadata).interfaceId, true);
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
    function mintTo(address _to, uint256 _amount) public virtual {
        if (!_canMint()) {
            revert ERC20Base_notAuthorized();
        }

        if (_amount < 1) {
            revert ERC20Base_zeroAmount();
        }

        _mint(_to, _amount);
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
        return msg.sender == owner();
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetContractURI() internal view virtual override returns (bool) {
        return msg.sender == _owner();
    }
}

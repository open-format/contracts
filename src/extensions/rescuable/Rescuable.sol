// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";

/**
 * @title Rescuable contract
 * @dev Allows a contract to have a function to rescue tokens sent by mistake.
 * The contract must implement the external rescueTokens function or similar,
 * that calls this contract's _rescueTokens.
 */
contract Rescuable {

    error Rescuable_zeroAddress();
    error Rescuable_zeroAmount();
    error Rescuable_transferFailed();
    
    /**
     * @dev Tokens rescued by the permissioned user
     */
    event TokensRescued(address indexed to, address indexed token, uint256 amount);

    /**
     * @dev Allows a permissioned user to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function _rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) internal {
        if (_to == address(0)) {
            revert Rescuable_zeroAddress();
        }
        if (_amount == 0) {
            revert Rescuable_zeroAmount();
        }
        IERC20 token = IERC20(_token);
        if (!token.transfer(_to, _amount)) {
            revert Rescuable_transferFailed();
        }
        emit TokensRescued(_to, _token, _amount);
    }
}

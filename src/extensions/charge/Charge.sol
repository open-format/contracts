// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ICharge} from "./ICharge.sol";
import {ChargeInternal} from "./ChargeInternal.sol";
import {IERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

abstract contract Charge is ICharge, ChargeInternal {
    /**
     * @notice Charge a user for a specific service.
     * @dev Transfers the specified `amount` of `tokens` from the `user` to the operator.
     * @param user The address of the user to be charged.
     * @param token The address of the ERC20 token used for payment.
     * @param amount The amount of tokens to be transferred.
     * @param chargeId A unique identifier for the charge.
     * @param chargeType The type of charge.
     */
    function chargeUser(address user, address token, uint256 amount, bytes32 chargeId, bytes32 chargeType) external {
        if (msg.sender != _operator()) {
            revert Charge_doNotHavePermission();
        }

        IERC20(token).transferFrom(user, _operator(), amount);

        emit ChargedUser(user, token, amount, chargeId, chargeType);
    }

    /**
     * @notice Set the required token balance for a specific token.
     * @dev Sets the required balance of tokens that users must maintain.
     * @param token The address of the ERC20 token.
     * @param balance The required balance to be set.
     */
    function setRequiredTokenBalance(address token, uint256 balance) external {
        if (msg.sender != _operator()) {
            revert Charge_doNotHavePermission();
        }

        _setRequiredTokenBalance(token, balance);

        emit RequiredTokenBalanceUpdated(token, balance);
    }

    /**
     * @notice Get the required token balance for a specific token.
     * @dev returns the required balance of tokens that users must maintain.
     * @param token The address of the ERC20 token.
     * @return uint256 The set required balance.
     */
    function getRequiredTokenBalance(address token) external view returns (uint256) {
        return _getRequiredTokenBalance(token);
    }

    /**
     * @notice Check if a user has sufficient funds.
     * @dev Returns true if the `user` has at least the required token balance and allowance for the given ERC20 token.
     * @param user The address of the user.
     * @param token The address of the ERC20 token.
     * @return bool True if the user has sufficient balance and allowance, otherwise false.
     */
    function hasFunds(address user, address token) external view returns (bool) {
        return _hasFunds(user, token, _getRequiredTokenBalance(token));
    }
}

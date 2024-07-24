// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {ICharge} from "./ICharge.sol";
import {ChargeInternal} from "./ChargeInternal.sol";
import {IERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {IERC2612} from "@solidstate/contracts/token/ERC20/permit/IERC2612.sol";

abstract contract Charge is ICharge, ChargeInternal {
    /**
     * @notice Charge a user for a specific service.
     * @dev Transfers the specified `amount` of `credit` tokens from the `user` to the operator.
     * @param user The address of the user to be charged.
     * @param credit The address of the ERC20 token used for payment.
     * @param amount The amount of tokens to be transferred.
     * @param chargeId A unique identifier for the charge.
     * @param chargeType The type of charge.
     */
    function chargeUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType) external {
        if (msg.sender != _operator()) {
            revert Charge_doNotHavePermission();
        }

        IERC20(credit).transferFrom(user, _operator(), amount);

        emit chargedUser(user, credit, amount, chargeId, chargeType);
    }

    /**
     * @notice Set the minimum credit balance required for a specific token.
     * @dev Sets the minimum balance of `credit` tokens that users must maintain.
     * @param credit The address of the ERC20 token.
     * @param balance The minimum balance to be set.
     */
    function setMinimumCreditBalance(address credit, uint256 balance) external {
        if (msg.sender != _operator()) {
            revert Charge_doNotHavePermission();
        }

        _setMinimumCreditBalance(credit, balance);

        emit minimumCreditBalanceUpdated(credit, balance);
    }

    /**
     * @notice Get the minimum credit balance required for a specific token.
     * @dev returns the minimum balance of `credit` tokens that users must maintain.
     * @param credit The address of the ERC20 token.
     * @return uint256 The set minimum balance.
     */
    function getMinimumCreditBalance(address credit) external view returns (uint256) {
        return _getMinimumCreditBalance(credit);
    }

    /**
     * @notice Check if a user has sufficient funds.
     * @dev Returns true if the `user` has at least the minimum credit balance and allowance for the given `credit` token.
     * @param user The address of the user.
     * @param credit The address of the ERC20 token.
     * @return bool True if the user has sufficient funds and allowance, otherwise false.
     */
    function hasFunds(address user, address credit) external view returns (bool) {
        return _hasFunds(user, credit, _getMinimumCreditBalance(credit));
    }
}

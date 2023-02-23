// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IApplicationFee {
    error Error_insufficientBalance();
    error Error_insufficientValue();
    error Error_unableToSendValue();
    error Error_currencies_and_approvals_must_be_the_same_length();
    error Error_currency_not_accepted();

    event PaidApplicationFee(address currency, uint256 amount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IPlatformFee {
    error Error_insufficientBalance();
    error Error_insufficientValue();
    error Error_unableToSendValue();

    event PaidPlatformFee(address currency, uint256 amount);
}

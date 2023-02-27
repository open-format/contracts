// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface IApplicationFee {
    error Error_currencies_and_approvals_must_be_the_same_length();
    error Error_currency_not_accepted();
    error Error_exceeds_max_percentBPS();

    event PaidApplicationFee(address currency, uint256 amount);

    /**
     * @notice gets the application fee for a given price
     * @param _price the given price of a transaction
     * @return recipient the address to pay the application fee to
     * @return amount the fee amount
     */
    function applicationFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount);
}

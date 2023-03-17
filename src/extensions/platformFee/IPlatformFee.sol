// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;

interface IPlatformFee {
    event PaidPlatformFee(address currency, uint256 amount);

    /**
     * @notice gets the platform fee for a given price
     * @param _price the given price of a transaction
     * @return recipient the address to pay the platform fee to
     * @return amount the fee amount
     */
    function platformFeeInfo(uint256 _price) external view returns (address recipient, uint256 amount);
}

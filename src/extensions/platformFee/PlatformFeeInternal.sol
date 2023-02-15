// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Global} from "../global/Global.sol";
import {IPlatformFee} from "./IPlatformFee.sol";

abstract contract PlatformFeeInternal is IPlatformFee, Global {
    /**
     * @dev returns base fee from globals contract
     */
    function _platformFeeInfo(uint256 _price) internal view returns (address reciever, uint256 amount) {
        (reciever, amount) = _getGlobals().platformFeeInfo(_price);
    }

    /**
     * @dev inspired by openzepplin Address.sendValue
     *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     */
    function _payPlatformFee(address recipient, uint256 amount) internal virtual {
        require(address(this).balance >= amount, "PlatformFee: insufficient balance");

        (bool success,) = recipient.call{value: amount}("");
        require(success, "PlatformFee: unable to send value, recipient may have reverted");

        emit PaidPlatformFee(address(0), amount);
    }
}

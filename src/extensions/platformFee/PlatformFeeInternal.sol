// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {Global} from "../global/Global.sol";
import {IPlatformFee} from "./IPlatformFee.sol";

abstract contract PlatformFeeInternal is IPlatformFee, Global {
    /**
     * @dev wrapper that calls platformFeeInfo from globals contract
     *      inspired by eip-2981 NFT royalty standard
     */
    function _platformFeeInfo(uint256 _price) internal view returns (address recipient, uint256 amount) {
        (recipient, amount) = _getGlobals().platformFeeInfo(_price);
    }

    /**
     * @dev sends ether to recipient
     *      inspired by openzepplin Address.sendValue
     *      https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
     */
    function _sendValue(address recipient, uint256 amount) internal virtual {
        if (address(this).balance < amount) {
            revert Error_insufficientBalance();
        }

        (bool success,) = recipient.call{value: amount}("");
        if (!success) {
            revert Error_unableToSendValue();
        }
    }

    /**
     * @dev     pays platform fee in ether, to be used in payable functions
     * @param   _price used to calculate platfrom fee, can be set to 0 for none priced functions
     * @return  remaining is the remaining ether balance after the platform fee has been paid
     */

    function _payPlatfromFee(uint256 _price) internal virtual returns (uint256 remaining) {
        (address recipient, uint256 amount) = _platformFeeInfo(_price);

        // ensure the ether being sent was included in the transaction
        if (msg.value < amount) {
            revert Error_insufficientValue();
        }
        remaining = msg.value - amount;

        if (amount > 0) {
            _sendValue(recipient, amount);

            emit PaidPlatformFee(address(0), amount);
        }
    }
}

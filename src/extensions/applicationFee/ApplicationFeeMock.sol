// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ApplicationFee, IApplicationFee} from "./ApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

import {CurrencyTransferLib} from "src/lib/CurrencyTransferLib.sol";

contract ApplicationFeeMock is ApplicationFee {
    /* INTERNAL HELPERS */

    function setApplicationFee(uint16 _percentBPS, address _recipient) external {
        _setApplicationFee(_percentBPS, _recipient);
    }

    function setAcceptedCurrencies(address[] memory _currencies, bool[] memory _approvals) external {
        _setAcceptedCurrencies(_currencies, _approvals);
    }

    /* STORAGE HELPERS */

    function percentBPS() external view returns (uint16) {
        return ApplicationFeeStorage.layout().percentageBPS;
    }

    function recipient() external view returns (address) {
        return ApplicationFeeStorage.layout().recipient;
    }

    function isCurrencyAccepted(address _currency) external view returns (bool) {
        return ApplicationFeeStorage.layout().acceptedCurrencies[_currency];
    }

    /* IMPLEMENTATION EXAMPLE */

    /**
     * @dev              pays application fee in ether or erc20 token, to be used in payable functions
     * @param _currency  the address of the currency, use address(0) for native token
     * @param _price     used to calculate application fee, can be set to 0 for none priced functions
     * @return remaining is the remaining balance after the application fee has been paid
     */

    function payApplicationFee(address _currency, uint256 _price)
        external
        payable
        onlyAcceptedCurrencies(_currency)
        returns (uint256 remaining)
    {
        (address to, uint256 amount) = _applicationFeeInfo(_price);

        if ((_currency == address(0)) && (amount > msg.value)) {
            revert CurrencyTransferLib.CurrencyTransferLib_insufficientValue();
        }

        CurrencyTransferLib.transferCurrency(_currency, msg.sender, to, amount);

        emit PaidApplicationFee(_currency, amount);

        remaining = _price - amount;
    }
}

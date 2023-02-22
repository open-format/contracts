// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ApplicationFee} from "./ApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

contract ApplicationFeeMock is ApplicationFee {
    function setApplicationFee(uint16 _percentBPS, address _recipient) external {
        _setApplicationFee(_percentBPS, _recipient);
    }

    function setAcceptedTokens(address[] memory _tokens, bool[] memory _approvals) external {
        _setAcceptedTokens(_tokens, _approvals);
    }

    function payApplicationFee(address _currency, uint256 _price) external returns (uint256 remaining) {
        return _payApplicationFee(_currency, _price);
    }
}

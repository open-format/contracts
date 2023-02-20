// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ApplicationFee} from "./ApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

contract ApplicationFeeMock is ApplicationFee {
    function setApplicationFee(uint256 _base, uint16 _percentBPS, address _recipient) external {
        _setApplicationFee(_base, _percentBPS, _recipient);
    }

    function setFeeMethod(ApplicationFeeStorage.FeeMethod _method) external {
        _setFeeMethod(_method);
    }

    function setSpecificToken(address _token) external {
        _setSpecificToken(_token);
    }

    function setAcceptedTokens(address[] memory _tokens, bool[] memory _approval) external {
        _setAcceptedTokens(_tokens, _approval);
    }

    function payApplicationFee(address _currency, uint256 _price) external returns (uint256 remaining) {
        return _payApplicationFee(_currency, _price);
    }
}

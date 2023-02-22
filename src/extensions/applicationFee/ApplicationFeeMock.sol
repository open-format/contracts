// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import {ApplicationFee, IApplicationFee} from "./ApplicationFee.sol";
import {ApplicationFeeStorage} from "./ApplicationFeeStorage.sol";

contract ApplicationFeeMock is ApplicationFee {
    /* INTERNAL HELPERS */

    function setApplicationFee(uint16 _percentBPS, address _recipient) external {
        _setApplicationFee(_percentBPS, _recipient);
    }

    function setAcceptedTokens(address[] memory _tokens, bool[] memory _approvals) external {
        _setAcceptedTokens(_tokens, _approvals);
    }

    function payApplicationFee(address _currency, uint256 _price) external payable returns (uint256 remaining) {
        return _payApplicationFee(_currency, _price);
    }

    /* STORAGE HELPERS */

    function percentBPS() external view returns (uint16) {
        return ApplicationFeeStorage.layout().percentageBPS;
    }

    function recipient() external view returns (address) {
        return ApplicationFeeStorage.layout().recipient;
    }

    function isTokenAccepted(address _token) external view returns (bool) {
        return ApplicationFeeStorage.layout().acceptedTokens[_token];
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import {IERC20, SafeERC20} from "@solidstate/contracts/utils/SafeERC20.sol";
import {SafeOwnable} from "@solidstate/contracts/access/ownable/SafeOwnable.sol";
import {Multicall} from "@solidstate/contracts/utils/Multicall.sol";

// TODO: move these constants to globals contract, they would all be configurable
address constant SCL = address(0x123); // social contract layer
address constant OFT = address(0x456); // OFT token
uint256 constant minimumOFTBalance = 10; // the minimum required balance so operators can conduct transactions

contract ChargeFacetInternals {
    // Can be used by other functions to restrict access based on balance
    function _hasFunds(address user, address credit, uint256 minimumBalance) internal view returns (bool) {
        return (IERC20(credit).balanceOf(user) <  minimumBalance &&
                IERC20(credit).allowance(user, address(this)) < minimumBalance);
    }

    function _minimumCreditBalance(address credit) internal view returns (uint256) {
        return ChargeFacetStorage.layout().minimumCreditBalance[credit];
    }

    function _setMinimumCreditBalance(address credit, uint256 amount) internal {
        ChargeFacetStorage.layout().minimumCreditBalance[credit] = amount;
    }
}

contract ChargeFacet is Multicall, SafeOwnable, ChargeFacetInternals {
    // Inspired by rewards events, adding a chargeId and chargeType for additional context
    // example -> chargeId  chargeId: "10tx" chargeType:"batch"
    event chargedUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType );
    event chargedApp(address operator, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType );


    function chargeUser(address user, address credit, uint256 amount, bytes32 chargeId, bytes32 chargeType) public onlyOwner {
        IERC20(credit).transferFrom(user, _owner(), amount);

        emit chargedUser(user, credit, amount, chargeId, chargeType);
    }

    function chargeApp(uint256 amount, bytes32 chargeId, bytes32 chargeType) public {
        // only openformat can call
        if (msg.sender != SCL) {
            revert();
        }

        IERC20(OFT).transferFrom(_owner(), SCL, amount);

        emit chargedApp(_owner(), OFT, amount, chargeId, chargeType);
    }

    // NOTE: formula for minBalance should be minUnitCost x chargeFrequency
    function setMinimumCreditBalance(address credit,uint256 balance) external onlyOwner {
      _setMinimumCreditBalance(credit, balance);
    }

     // checks operators OFT balance and allowance is more than minimumOFTBalance
    function hasFunds() external view returns (bool) {
        return _hasFunds(_owner(), OFT, minimumOFTBalance);
    }
    // NOTE: would read this for API reads as well.
    // checks users credit balance and allowance is more than minimumCreditBalance
    function userHasFunds(address user, address credit) external view returns (bool) {
        return _hasFunds(user, credit, _minimumCreditBalance(credit));
    }
}

library ChargeFacetStorage {
    struct Layout {
        mapping(address => uint256) minimumCreditBalance; // credit => minimum balance required to conduct actions.
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("openformat.contracts.storage.ChargeFacet");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;

        // slither-disable-next-line assembly
        assembly {
            l.slot := slot
        }
    }
}


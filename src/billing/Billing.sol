// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {IERC20} from "@solidstate/contracts/interfaces/IERC20.sol";
import {Math} from "@solidstate/contracts/utils/Math.sol";
import {IBilling} from "./IBilling.sol";
import {Governed} from "../extensions/governed/Governed.sol";
import {Rescuable} from "../extensions/rescuable/Rescuable.sol";
import {IOwnable} from "@solidstate/contracts/access/ownable/IOwnable.sol";

/**
 * @title Billing Contract
 * @dev The billing contract allows for Graph Tokens to be added by a user. The token can then
 * be pulled by a permissioned set of users named 'collectors'. It is owned and controlled by the 'governor'.
 */
contract Billing is IBilling, Governed, Rescuable {

    error Billing_invalidAppAddress();
    error Billing_invalidCollectorAddress();
    error Billing_invalidDestinationAddress();
    error Billing_invalidTokenAddress();
    error Billing_invalidDeadline();
    error Billing_zeroAmount();
    error Billing_notAuthorised();
    error Billing_insufficientBalance();
    error Billing_appsAndAmountssMustBeTheSameLength();
    error Billing_noteEnoughTokensAvailable();
    error Billing_tokenUpdateNotAllowed();

    // Struct to represent a bill
    struct Bill {
        uint256 amount;
        uint256 deadline;
    }

    // The contract for interacting with The Graph Token
    address private oftToken;
    
    // Whether is possible to update the token
    bool _tokenUpdatable;

    // True for addresses that are Collectors
    mapping(address => bool) public isCollector;

    // maps user address --> app billing balance
    mapping(address => uint256) public appBalances;

    // Mapping to store app bills
    mapping(address => Bill) private bills;

    // Amount of tokens that had been paid and are available to be transferred
    uint256 private _paidAmount;

    /**
     * @notice Constructor function for the Billing contract
     * @param _collector   Initial collector address
     * @param _token     OFT Token address
     * @param _governor  Governor address
     */
    constructor(address _collector, address _token, address _governor, bool _canUpdateToken) Governed(_governor) {
        _setCollector(_collector, true);
        oftToken = _token;
        _tokenUpdatable = _canUpdateToken;
    }

    /**
     * @dev Check if the caller is a Collector.
     */
    modifier onlyCollector() {
        if (!isCollector[msg.sender]) {
            revert Billing_notAuthorised();
        }
        _;
    }

    /**
     * @notice Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function setCollector(address _collector, bool _enabled) external override onlyGovernor {
        _setCollector(_collector, _enabled);
    }

    /**
     * @notice Add tokens into the billing contract for any user
     * @dev Ensure oftToken.approve() is called on the billing contract first
     * @param _app  App that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function deposit(address _app, uint256 _amount) external {
        if (_amount <= 0) {
            revert Billing_zeroAmount();
        }
        if (_app == address(0)) {
            revert Billing_invalidAppAddress();
        }
        appBalances[_app] += _amount;
        _payBills(_app); // Pay bills
        IERC20(oftToken).transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(address _app, uint256 _amount) external {
        if (_app == address(0)) {
            revert Billing_invalidAppAddress();
        }
        if (msg.sender != IOwnable(_app).owner()) {
            revert Billing_notAuthorised();
        }
        if (_amount <= 0) {
            revert Billing_zeroAmount();
        }
        if (appBalances[_app] < _amount) {
            revert Billing_insufficientBalance();
        }
        appBalances[_app] -= _amount;
        IERC20(oftToken).transfer(msg.sender, _amount);
    }

    /**
     * @notice Add tokens into the billing contract in bulk
     * @dev Ensure oftToken.approve() is called on the billing contract first
     * @param _apps  Array of Apps where to add tokens
     * @param _amount  Array of amount of tokens to add to each account
     */
    function depositToMany(address[] calldata _apps, uint256[] calldata _amount) external {
        if (_apps.length != _amount.length) {
            revert Billing_appsAndAmountssMustBeTheSameLength();
        }

        // Get total amount to add
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amount.length; i++) {
            if (_amount[i] <= 0) {
                revert Billing_zeroAmount();
            }
            totalAmount += _amount[i];
        }
        // Add each amount
        for (uint256 i = 0; i < _apps.length; i++) {
            address app = _apps[i];
            if (app == address(0)) {
                revert Billing_invalidAppAddress();
            }
            appBalances[app] += _amount[i];
            _payBills(app); // Pay bills
        }
        IERC20(oftToken).transferFrom(msg.sender, address(this), totalAmount);
    }

    /**
     * @notice Allows the Governor to rescue any ERC20 tokens sent to this contract by accident
     * @param _to  Destination address to send the tokens
     * @param _token  Token address of the token that was accidentally sent to the contract
     * @param _amount  Amount of tokens to pull
     */
    function rescueTokens(address _to,address _token,uint256 _amount) external onlyGovernor {
        _rescueTokens(_to, _token, _amount);
    }

    /**
     * @dev Send tokens to a destination account, decrease available tokens amount accordingly
     * @param _to Address where to send tokens
     * @param _amount Amount of tokens to send
     */
    function sendTokens(address _to, uint256 _amount) external onlyCollector {
        if (_to == address(0)) {
            revert Billing_invalidDestinationAddress();
        }
        if (_amount <= 0) {
            revert Billing_zeroAmount();
        }
        if (_amount > _paidAmount) {
            revert Billing_noteEnoughTokensAvailable();
        }
            
        _paidAmount -= _amount;
        IERC20(oftToken).transfer(_to, _amount);
    }

    /**
     * @dev Send all available tokens to a destination account
     * @param _to Address where to send tokens
     */
    function sendAllTokens(address _to) external onlyCollector {
        if (_to == address(0)) {
            revert Billing_invalidDestinationAddress();
        }
            
        _paidAmount = 0;
        IERC20(oftToken).transfer(_to, _paidAmount);
    }

    /**
     * @dev Returns the amount of tokens that have been paid by all apps and are available to be transferred
     */
    function paidTokensAmount() external view onlyCollector returns (uint256) {
        return _paidAmount;
    }


    /**
     * @dev Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function _setCollector(address _collector, bool _enabled) internal {
        if (_collector == address(0)) {
            revert Billing_invalidCollectorAddress();
        }
        isCollector[_collector] = _enabled;
    }

    /**
     * @dev Pays current bills for an app. It takes the amount to pay from the app balance and increases
     * the available tokens amount accordingly
     * @param _app App to pay the bill
     */
    function _payBills(address _app) private {
        uint256 amountToPay = Math.min(bills[_app].amount, appBalances[_app]);
        if (amountToPay > 0) {
            appBalances[_app] -= amountToPay;
            bills[_app].amount -= amountToPay;
            _paidAmount += amountToPay;
        }
    }

    /**
     * @dev Function to check if an App has paid all bills
     * @param _app App to check
     */
    function hasPaid(address _app) external view returns (bool) {
        return bills[_app].amount == 0 || bills[_app].deadline > block.timestamp;
    }

    /**
     * @dev Creates or updates a bill for an app
     * @param _app App that receives the bill
     * @param _amount Amount to add to the Bill
     * @param _deadline Deadline to pay for the Bill
    */
    function createBill(address _app, uint256 _amount, uint256 _deadline) external onlyCollector {
        if (_app == address(0)) {
            revert Billing_invalidAppAddress();
        }
        if (_amount <= 0) {
            revert Billing_zeroAmount();
        }
        if (_deadline <= block.timestamp) {
            revert Billing_invalidDeadline();
        }
        bills[_app] = Bill((bills[_app].amount + _amount), _deadline);
        _payBills(_app); // Pay the newly created bill
    }

    /**
     * @dev Creates or updates bills for a list of apps
     * @param _apps Array of apps that receive the bill
     * @param _amounts Array of smounts for each bill
     * @param _deadlines Array of deadlines for each bill
    */
    function createBillToMany(address[] calldata _apps, uint256[] calldata  _amounts, uint256[] calldata  _deadlines) external onlyCollector {
        require(_apps.length == _amounts.length && _apps.length == _deadlines.length, "Lengths not equal");

        for (uint256 i = 0; i < _apps.length; i++) {
            if (_apps[i] == address(0)) {
                revert Billing_invalidAppAddress();
            }
            if (_amounts[i] <= 0) {
                revert Billing_zeroAmount();
            }
            if (_deadlines[i] <= block.timestamp) {
                revert Billing_invalidDeadline();
            }

            bills[_apps[i]] = Bill((bills[_apps[i]].amount + _amounts[i]), _deadlines[i]);
            _payBills(_apps[i]); // Pay the newly created bill
        }
    }

    /**
     *  @dev Returns the balance for an app
     *  @param _app App to return balance
    */
    function getBalance(address _app) external view returns (uint256) {
        return appBalances[_app];
    }
    
    /**
     *  @dev Returns the Bill for an app
     *  @param _app App to return bill
    */
    function getBill(address _app) external view returns (uint256 amount, uint256 deadline) {
        return (bills[_app].amount, bills[_app].deadline);
    }

    /**
     * @dev Returns the token address
    */
    function getToken() external view returns (address) {
        return oftToken;
    }

    /**
     * @dev Sets the token address. It is assumed that tokens have already been minted for this contract.
     * @param _token New token address
    */
    function setToken(address _token) external onlyGovernor {
        if(!_tokenUpdatable) {
            revert Billing_tokenUpdateNotAllowed();
        }
        if (_token == address(0)) {
            revert Billing_invalidTokenAddress();
        }

        oftToken = _token;
    }

}

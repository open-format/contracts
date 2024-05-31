// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IBilling {
    /**
     * @dev Set or unset an address as an allowed Collector
     * @param _collector  Collector address
     * @param _enabled True to set the _collector address as a Collector, false to remove it
     */
    function setCollector(address _collector, bool _enabled) external; // onlyGovernor

    /**
     * @dev Add tokens into the billing contract for an App
     * @param _app  App that tokens are being added to
     * @param _amount  Amount of tokens to add
     */
    function deposit(address _app, uint256 _amount) external ;

    /**
     * @dev Add tokens into the billing contract in bulk
     * Ensure oftToken.approve() is called on the billing contract first
     * @param _apps  Array of Apps where to add tokens
     * @param _amount  Array of amount of tokens to add to each account
     */
    function depositToMany(address[] calldata _apps, uint256[] calldata _amount) external;

    /**
     * @dev Remove tokens from the billing contract
     * Tokens will be removed from the app balance
     * @param _app  App that tokens are being removed from
     * @param _amount  Amount of tokens to remove
     */
    function withdraw(address _app, uint256 _amount) external;

    /**
     * @dev Send tokens to a destination account
     * @param _to Address where to send tokens
     * @param _amount Amount of tokens to send
     */
    function sendTokens(address _to, uint256 _amount) external;

    /**
     * @dev Send all available tokens to a destination account
     * @param _to Address where to send tokens
     */
    function sendAllTokens(address _to) external;

    /**
     * @dev Returns the amount of tokens that have been paid by all apps and are available to be transferred
     */
    function paidTokensAmount() external view returns (uint256);

    /**
     * @dev Function to check if an App has paid all bills
     * @param _app App to check
     */
    function hasPaid(address _app) external view returns (bool);

    /**
     * @dev Creates or updates a bill for an app
     * @param _app App that receives the bill
     * @param _amount Amount to add to the Bill
     * @param _deadline Deadline to pay for the Bill
    */
    function createBill(address _app, uint256 _amount, uint256 _deadline) external;

    /**
     * @dev Creates or updates bills for a list of apps
     * @param _apps Array of apps that receive the bill
     * @param _amounts Array of smounts for each bill
     * @param _deadlines Array of deadlines for each bill
    */
    function createBillToMany(address[] calldata _apps, uint256[] calldata  _amounts, uint256[] calldata  _deadlines) external;

    /**
     *  @dev Returns the balance for an app
     *  @param _app App to return balance
    */
    function getBalance(address _app) external view returns (uint256);
    
    /**
     *  @dev Returns the Bill for an app
     *  @param _app App to return bill
    */
    function getBill(address _app) external view returns (uint256 amount, uint256 deadline);

    /**
     * @dev Returns the token address
    */
    function getToken() external view returns (address);

    /**
     * @dev Sets the token address. It is assumed that tokens have already been minted for this contract.
     * @param _token New token address
    */
    function setToken(address _token) external;

}

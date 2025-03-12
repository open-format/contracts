// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IDeployer {
  function deploy() external returns (address);
  function deployTest() external returns (address);
  function export() external;
  function selectors() external returns (bytes4[] memory);
}
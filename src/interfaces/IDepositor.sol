// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IDepositor {
    function deposit(uint256 amount, bool lock, bool stake, address user) external;
}

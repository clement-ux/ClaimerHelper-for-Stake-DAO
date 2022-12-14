// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IZapBalancer {
    function zapFromBal(uint256 _amount, bool _lock, bool _stake, uint256 _minAmount, address _user) external;
}

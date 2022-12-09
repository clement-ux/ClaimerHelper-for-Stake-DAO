// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IVault {
    function transferFrom(address sender, address receipient, uint256 amount) external;

    function withdraw(uint256 _shares) external;

    function balanceOf(address user) external view returns (uint256);
}

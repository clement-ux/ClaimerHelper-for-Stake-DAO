// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IFraxUsdc {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external;
}

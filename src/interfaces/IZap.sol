// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IZap {
    function add_liquidity(address _pool, uint256[3] memory _deposit_amounts, uint256 _min_mint_amount)
        external
        payable;
}
